#!/usr/bin/env python
"""
Patch KCWI DRP's StartBokeh to use a fixed session ID.
This allows viewing plots at: http://localhost:5006/?bokeh-session-id=kcwi
"""
import sys

# Patch the StartBokeh module to use a fixed session ID
PATCH_CODE = '''
from bokeh.client import pull_session as _original_pull_session

def _patched_pull_session(*args, **kwargs):
    """Wrapper that forces a fixed session_id for KCWI plots."""
    if 'session_id' not in kwargs:
        kwargs['session_id'] = 'kcwi'
    if 'url' not in kwargs:
        kwargs['url'] = 'http://localhost:5006'
    return _original_pull_session(*args, **kwargs)

# Replace pull_session globally
import bokeh.client
bokeh.client.pull_session = _patched_pull_session

# Also patch in the session module
import bokeh.client.session
bokeh.client.session.pull_session = _patched_pull_session
'''

exec(PATCH_CODE)
print("Bokeh session patched: plots will be available at http://localhost:5006/?bokeh-session-id=kcwi", file=sys.stderr)

# Patch kcwidrp.primitives.get_master_name to handle table indexing edge case
def _patch_get_master_name():
    """
    Monkeypatch for kcwidrp.primitives.get_master_name() to fix an exception
    that occurs when tab['filename'][loc] fails (e.g., when tab is not a table).
    """
    try:
        from kcwidrp import primitives
        from pathlib import Path
        
        # Get the original strip_fname function
        strip_fname = primitives.strip_fname
        
        def get_master_name_patched(tab, target_type, loc=0):
            """
            Add a specific tag to an output fits filename read from a proc table.

            Args:
                tab (proc table): proc table source of filename.
                target_type (str): suffix to add after underscore.
                loc (int): row within table in `tab`, defaults to 0.

            Returns:
                (str): constructed filename from input tab entry and target_type.
            """
            try:
                stem = tab['filename'][loc]
            except:
                stem = tab[loc]
            res = Path(strip_fname(stem) + '_' +
                       target_type.lower() + ".fits").name
            return res
        
        # Apply the patch
        primitives.get_master_name = get_master_name_patched
        print("kcwidrp.primitives.get_master_name patched", file=sys.stderr)
        return True
    except ImportError:
        return False

# Try to patch immediately (in case kcwidrp is already imported)
if not _patch_get_master_name():
    # kcwidrp not yet imported - install an import hook to patch it when loaded
    import importlib.abc
    import importlib.machinery
    
    class KCWIPatchFinder(importlib.abc.MetaPathFinder):
        def find_spec(self, fullname, path, target=None):
            return None  # Let normal import proceed
    
    class KCWIPatchLoader(importlib.abc.Loader):
        pass
    
    _original_import = __builtins__.__import__ if hasattr(__builtins__, '__import__') else __import__
    _patch_applied = False
    
    def _patching_import(name, *args, **kwargs):
        global _patch_applied
        result = _original_import(name, *args, **kwargs)
        if not _patch_applied and name.startswith('kcwidrp'):
            if _patch_get_master_name():
                _patch_applied = True
        return result
    
    try:
        __builtins__.__import__ = _patching_import
    except (AttributeError, TypeError):
        # __builtins__ might be a dict in some contexts
        if isinstance(__builtins__, dict):
            __builtins__['__import__'] = _patching_import

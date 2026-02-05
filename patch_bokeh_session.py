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

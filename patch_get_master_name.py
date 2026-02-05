#!/usr/bin/env python
"""
Build-time patch for kcwidrp.primitives.kcwi_file_primitives.get_master_name().

Directly modifies the installed source file so the fix is permanent.
The original get_master_name() does:
    res = Path(strip_fname(tab['filename'][loc]) + '_' + ...
which can raise an exception. This patch replaces it with a version
that falls back to tab[loc] when tab['filename'][loc] fails.
"""
import inspect
from pathlib import Path

# Locate the installed kcwi_file_primitives module
import kcwidrp.primitives.kcwi_file_primitives as mod
source_file = Path(inspect.getfile(mod))
print(f"Patching: {source_file}")

original = source_file.read_text()

# The original code block we're replacing
old_code = """\
    res = Path(strip_fname(tab['filename'][loc]) + '_' +
               target_type.lower() + ".fits").name
    return res"""

new_code = """\
    try:
        stem = tab['filename'][loc]
    except:
        stem = tab[loc]
    res = Path(strip_fname(stem) + '_' +
               target_type.lower() + ".fits").name
    return res"""

if old_code in original:
    patched = original.replace(old_code, new_code, 1)
    source_file.write_text(patched)
    print("get_master_name() patched successfully.")
elif new_code in original:
    print("get_master_name() is already patched, skipping.")
else:
    print("WARNING: Could not find expected code in get_master_name().")
    print("The function may have changed upstream. Manual review needed.")
    raise SystemExit(1)

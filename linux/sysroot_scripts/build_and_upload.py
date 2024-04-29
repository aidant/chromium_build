#!/usr/bin/env python3
# Copyright 2016 The Chromium Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Automates running sysroot_creator.py for each supported arch.
"""

import concurrent.futures
import json
import os
import sys
import textwrap

import sysroot_creator

SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))


def build_and_upload(arch):
    try:
        sysroot_creator.build_sysroot(arch)
        result = sysroot_creator.upload_sysroot(arch)
        return (arch, True, result)  # (architecture, success, result)
    except Exception as e:
        return (arch, False, str(e))  # (architecture, failure, error message)


def main():
    with concurrent.futures.ThreadPoolExecutor() as executor:
        # Map the function over the architectures
        futures = [
            executor.submit(build_and_upload, arch)
            for arch in sysroot_creator.TRIPLES
        ]

        failures = 0
        results = {}
        for future in concurrent.futures.as_completed(futures):
            arch, success, result = future.result()
            if not success:
                failures += 1
            name = (f"{sysroot_creator.DISTRO}_{sysroot_creator.RELEASE}" +
                    f"_{arch.lower()}-sysroot")
            results[name] = (success, result)

    globals = {"Str": lambda x: x, "Var": lambda x: x}
    deps = open(os.path.join(SCRIPT_DIR, "..", "..", "..", "DEPS")).read()
    exec(deps, globals)
    updates = {}

    print("SYSROOT CREATION SUMMARY")
    for name, (success, result) in results.items():
        status = "SUCCESS" if success else "FAILURE"
        print(name, status, sep=":\t")
        key = f"src/build/linux/{name}"
        updates[key] = globals["deps"][key]
        if success:
            result = " ".join(result.splitlines()[1:])
            updates[key]["objects"] = json.loads(result)["<path>"]["objects"]

    print("Update DEPS with the following entries:")
    entries = json.dumps(
        updates,
        sort_keys=True,
        indent=2,
        separators=(",", ": "),
    )
    # Format with single quotes and trailing commas.
    print("\n".join(line if any(line.endswith(c)
                                for c in "[{,") else line + ","
                    for line in entries.replace('"', "'").splitlines())[:-1])

    if not failures:
        key = (sysroot_creator.ARCHIVE_TIMESTAMP + "-" +
               sysroot_creator.SYSROOT_RELEASE)
        sysroot_gni = textwrap.dedent(f"""\
            # Copyright 2024 The Chromium Authors
            # Use of this source code is governed by a BSD-style license that
            # can be found in the LICENSE file.

            # This file was generated by
            # build/linux/sysroot_scripts/build_and_upload.py

            cr_sysroot_key = "{key}"
        """)
        fname = os.path.join(SCRIPT_DIR, "sysroot.gni")
        with open(fname, "w") as f:
            f.write(sysroot_gni)

    return failures


if __name__ == "__main__":
    sys.exit(main())

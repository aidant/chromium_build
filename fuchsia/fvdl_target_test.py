#!/usr/bin/env python3
# Copyright 2021 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Tests different flags to see if they are being used correctly"""

import boot_data
import common
import os
import tempfile
import unittest
import unittest.mock as mock

from argparse import Namespace
from fvdl_target import FvdlTarget, _SSH_KEY_DIR


class TestBuildCommandFvdlTarget(unittest.TestCase):
  def setUp(self):
    self.args = Namespace(out_dir='outdir',
                          system_log_file=None,
                          target_cpu='x64',
                          require_kvm=True,
                          enable_graphics=False,
                          hardware_gpu=False,
                          with_network=False,
                          ram_size_mb=8192,
                          logs_dir=None)
    common.EnsurePathExists = mock.MagicMock(return_value='image')
    boot_data.ProvisionSSH = mock.MagicMock()
    FvdlTarget.Shutdown = mock.MagicMock()

  def testBasicEmuCommand(self):
    with FvdlTarget.CreateFromArgs(self.args) as target:
      build_command = target._BuildCommand()
      self.assertIn(target._FVDL_PATH, build_command)
      self.assertIn('--sdk', build_command)
      self.assertIn('start', build_command)
      self.assertNotIn('--noacceleration', build_command)
      self.assertIn('--headless', build_command)
      self.assertNotIn('--host-gpu', build_command)
      self.assertNotIn('-N', build_command)
      self.assertIn('--device-proto', build_command)
      self.assertNotIn('--emulator-log', build_command)
      self.assertNotIn('--envs', build_command)
      self.assertTrue(os.path.exists(target._device_proto_file.name))
      correct_ram_amount = False
      with open(target._device_proto_file.name) as file:
        for line in file:
          if line.strip() == 'ram:  8192':
            correct_ram_amount = True
            break
      self.assertTrue(correct_ram_amount)

  def testBuildCommandCheckIfNotRequireKVMSetNoAcceleration(self):
    self.args.require_kvm = False
    with FvdlTarget.CreateFromArgs(self.args) as target:
      self.assertIn('--noacceleration', target._BuildCommand())

  def testBuildCommandCheckIfNotEnableGraphicsSetHeadless(self):
    self.args.enable_graphics = True
    with FvdlTarget.CreateFromArgs(self.args) as target:
      self.assertNotIn('--headless', target._BuildCommand())

  def testBuildCommandCheckIfHardwareGpuSetHostGPU(self):
    self.args.hardware_gpu = True
    with FvdlTarget.CreateFromArgs(self.args) as target:
      self.assertIn('--host-gpu', target._BuildCommand())

  def testBuildCommandCheckIfWithNetworkSetTunTap(self):
    self.args.with_network = True
    with FvdlTarget.CreateFromArgs(self.args) as target:
      self.assertIn('-N', target._BuildCommand())

  def testBuildCommandCheckRamSizeNot8192SetRamSize(self):
    custom_ram_size = 4096
    self.args.ram_size_mb = custom_ram_size
    with FvdlTarget.CreateFromArgs(self.args) as target:
      self.assertIn('--device-proto', target._BuildCommand())
      self.assertTrue(os.path.exists(target._device_proto_file.name))
      correct_ram_amount = False
      with open(target._device_proto_file.name, 'r') as f:
        self.assertTrue('  ram:  {}\n'.format(custom_ram_size) in f.readlines())

  def testBuildCommandCheckEmulatorLogSetup(self):
    with tempfile.TemporaryDirectory() as logs_dir:
      self.args.logs_dir = logs_dir
      with FvdlTarget.CreateFromArgs(self.args) as target:
        emu_command = []
        target._ConfigureEmulatorLog(emu_command)
        self.assertIn('--emulator-log', emu_command)
        self.assertIn('--envs', emu_command)


if __name__ == '__main__':
  unittest.main()

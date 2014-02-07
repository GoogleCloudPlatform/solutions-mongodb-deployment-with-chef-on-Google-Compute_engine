# Copyright 2013 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

chef_gem "knife-google"

Gem.clear_paths

require 'google/api_client'
require 'multi_json'
require 'google/compute/resource_collection'
require 'google/compute'

# Creates a persistent disk in a zone.
#
pdisk node['gceutil']['disk'] do
  size      node['gceutil']['disk_size_gb']
  action    "create"
  zone      node['gceutil']['zone']
end

# Attaches a persistent disk to current node. If you want to attache the disk
# to a different instance, use the "instance" parameter to specify the instance
# name.
#
pdisk node['gceutil']['disk'] do
  action    "attach"
  device    node['gceutil']['device']
  zone      node['gceutil']['zone']
end

# Creates a mounting point directory.
#
directory node['gceutil']['mountdir'] do
  owner "root"
  group "root"
  action :create
end

# Unmounts a persistent disk directory.
#
#pdisk "umount the disk" do
#  action    "umount"
#  mountdir  node['gceutil']['mountdir']
#end

# Mounts a attached device to a specified mounting point.
#
pdisk "mount the disk" do
  action      "mount"
  device      node['gceutil']['device']
  mountdir    node['gceutil']['mountdir']
end

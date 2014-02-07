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


# Overwrite some of the default attributes.
#
node.default.mongodb.dbpath = node.mymongodb.dbpath

# Includes the mongod package installation.
#
include_recipe "mongodb::10gen_repo"

# Stop mongodb service is present.
#
service "mongodb" do
  action [:stop]
end

############################
# Unmounts a persistent disk directory.
#
pdisk "umount the disk" do
  action    "umount"
  mountdir   node['mongodb']['dbpath']
  zone      node['mymongodb']['zone']
end

# Detaches a persistent disk.
#
pdisk "detach a disk" do
  action    "detach"
  device    node['mymongodb']['device']
  zone      node['mymongodb']['zone']
end

# Deletes a persistent disk.
#
pdisk node['mymongodb']['disk']['name'] do
  action    "delete"
  zone      node['gceutil']['zone']
  zone      node['mymongodb']['zone']
end
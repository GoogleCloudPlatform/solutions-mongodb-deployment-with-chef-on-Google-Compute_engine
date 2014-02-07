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
  action [:disable]
end

# Creates a persistent disk in a zone.
#
pdisk node['mymongodb']['disk']['name'] do
  size      node['mymongodb']['disk']['size']
  action    "create"
  zone      node['mymongodb']['zone']
end

# Attaches a persistent disk to current node. If you want to attache the disk
# to a different instance, use the "instance" parameter to specify the instance
# name.
#
pdisk node['mymongodb']['disk']['name'] do
  action    "attach"
  device    node['mymongodb']['device']
  zone      node['mymongodb']['zone']
end

# Creates a mounting point directory.
#
directory node['mongodb']['dbpath'] do
  owner node[:mongodb][:user]
  group node[:mongodb][:group]
  action :create
end

# Mounts a attached device to a specified mounting point.
#
pdisk "mount the disk" do
  action      "mount"
  device      node['mymongodb']['device']
  mountdir    node['mongodb']['dbpath']
end

########################Install mongodb#############
#
package node[:mongodb][:package_name] do
  action :install
  version node[:mongodb][:package_version]
end


# Create keyFile if specified
if node[:mongodb][:key_file]
  file "/etc/mongodb.key" do
    owner node[:mongodb][:user]
    group node[:mongodb][:group]
    mode  "0600"
    backup false
    content node[:mongodb][:key_file]
  end
end

# Stop mongodb service is present.
#
service "mongodb" do
  action [:disable]
end

mongodb_instance node['mongodb']['instance_name'] do
  mongodb_type "mongod"
  bind_ip      node['mongodb']['bind_ip']
  port         node['mongodb']['port']
  logpath      node['mongodb']['logpath']
  dbpath       node['mongodb']['dbpath']
  enable_rest  node['mongodb']['enable_rest']
  smallfiles   node['mongodb']['smallfiles']
end

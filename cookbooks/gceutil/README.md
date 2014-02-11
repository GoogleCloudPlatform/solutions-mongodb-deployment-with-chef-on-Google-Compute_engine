gceutil Cookbook
============
A sample cookbook to automate Google Compute Engine instance configuration.
Right now, the cookbook only support Persistent Disk configuration.

Requirements
------------
The cookbook depends on the ruby gem "knife-google".

Attributes
----------
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['gceutil']['zone']</tt></td>
    <td>String</td>
    <td>The name of the Google Compute Engine zone.</td>
    <td><tt>""</tt></td>
  </tr>
  <tr>
    <td><tt>['gceutil']['disk_size_gb']</tt></td>
    <td>Integer</td>
    <td>Persistent disk size in GB.</td>
    <td><tt>10</tt></td>
  </tr>
  <tr>
    <td><tt>['gceutil']['disk']</tt></td>
    <td>String</td>
    <td>The name of persistent disk.</td>
    <td><tt>"sample-disk"</tt></td>
  </tr>
  <tr>
    <td><tt>['gceutil']['device']</tt></td>
    <td>String</td>
    <td>The device name when attaching a persistent disk to an instance.</td>
    <td><tt>"pd0"</tt></td>
  </tr>
  <tr>
    <td><tt>['gceutil']['mountdir']</tt></td>
    <td>String</td>
    <td>The name of the directory where the disk is mounted.</td>
    <td><tt>"sample_data"</tt></td>
  </tr>
</table>

Usage
-----
Demonstrates you could create, attach a disk to an instance, detach the disk,
and delete the disk. To use it, just include `gceutil` in your node's
`run_list` and configure the attributes such as the compute zone and disk size
etc.

<code>
{
  "name":"my_node",
  "run_list": [
    "recipe[gceutil]"
  ]
}
</code>

#### gceutil::create_disk
Creates a new persistent disk.

#### gceutil::attach_disk
Attaches a persistent disk to an instance.

#### gceutil::detach_disk
Detaches a persistent disk from an instance.

#### gceutil::delete_disk
Deletes an existing persistent disk.

Contributing
------------
1. Developed the sample Cookbook.

License
--------
Licensed under the Apache License, Version 2.0

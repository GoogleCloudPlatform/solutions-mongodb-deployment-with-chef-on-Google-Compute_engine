mymongodb Cookbook
==================
A sample mongodb deployment cookbook.

Requirements
------------

#### packages
- `mongodb` - mymongodb installs the mongodb software.
- `knife-google` - mymongodb needs the knife-google gem.
- `gceutil` - mymongodb depends on gceutil cookbook for persistent disk
              management.
- `mongodb` - mymongodb depends on the mongodb cookbook for mongodb management.

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
    <td><tt>['mymongodb']['zone']</tt></td>
    <td>String</td>
    <td>The name of the Google Compute Engine zone.</td>
    <td><tt>""</tt></td>
  </tr>
  <tr>
    <td><tt>['mymongodb']['disk']['size']</tt></td>
    <td>Integer</td>
    <td>Persistent disk size in GB.</td>
    <td><tt>10</tt></td>
  </tr>
  <tr>
    <td><tt>['mymongodb']['disk']['name']</tt></td>
    <td>String</td>
    <td>The name of persistent disk.</td>
    <td><tt>"sample-disk"</tt></td>
  </tr>
  <tr>
    <td><tt>['mymongodb']['device']</tt></td>
    <td>String</td>
    <td>The device name when attaching a persistent disk to an instance.</td>
    <td><tt>"pd"</tt></td>
  </tr>
  <tr>
    <td><tt>['mymongodb']['dbpath']</tt></td>
    <td>String</td>
    <td>The name of the directory where the disk is mounted as well as the mongdb dbpath.</td>
    <td><tt>"/mongodb/data"</tt></td>
  </tr>
</table>

Usage
-----
#### mymongodb::default
Creates a persistent disk, attach the disk, and then install and run mongodb
using the disk as storage. To use it, just include `mymongodb` in your node's
`run_list` and configure the attributes such as the compute zone and disk size
etc.

<code>
{
  "name":"my_node",
  "run_list": [
    "recipe[mymongodb]"
  ]
}
</code>

Contributing
------------
1. Developed the sample Cookbook.

License
--------
Licensed under the Apache License, Version 2.0

name             'mymongodb'
maintainer       'YOUR_COMPANY_NAME'
maintainer_email 'YOUR_EMAIL'
license          'All rights reserved'
description      'Installs/Configures mymongodb'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends "mongodb",">= 0.13.4"
depends "gceutil", ">= 0.1.0"

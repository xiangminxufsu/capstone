
## Installation

### Client

We need additional services to install:

    $ curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
    $ sudo apt-get install -y make build-essential nodejs

Clone the test repo and uncompress the test data files.

    $ git clone https://github.com/xiangminxufsu/capstone.git
    $ cd capstone
    $ sudo npm install
    $ sudo npm run data

### Server

    $ sudo apt-get install -y unzip default-jre binutils numactl collectd nodejs

To install all databases and import the test dataset:

    $ ./setupAll.sh

## Run complete test setup

To run the complete test against every database, we simply execute `runAll.sh`.

    ./runAll.sh <server-ip> <num-runs>
### test
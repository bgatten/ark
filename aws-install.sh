cd ~
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Confirm Installation
aws --version

aws configure

# AWS Access Key ID [None]: REALACCESSKEYID
# AWS Secret Access Key [None]: REALSECRETACCESSKEY
# Default region name [None]: us-west-1 # make sure it is us-west-1
# Default output format [None]: # leave blank
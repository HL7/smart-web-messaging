# SMART Web Messaging Implementation Guide
The SMART Web Messaging Implementation Guide content has moved from this README to [fsh/ig-data/input/pagecontent/index.md](https://github.com/HL7/smart-web-messaging/blob/master/fsh/ig-data/input/pagecontent/index.md).  This document is used to feed the IG autopublisher, which populates: <https://build.fhir.org/ig/HL7/smart-web-messaging/>

# Published Content
The IG autobuilder automatically publishes on pushes to the main branch of this repo via a GitHub Webhook.  It typically takes a few minutes for the build to detect changes and run.

## Autobuilder
More details on the autobuilder are here: <https://github.com/FHIR/auto-ig-builder#fhir-implementation-guide-auto-builder>

## Latest
You can view the latest published content here: <https://build.fhir.org/ig/HL7/smart-web-messaging/>

## Troubleshooting
If you don't see published content when you view that link, it means the autobuilder may be failing to build and publish the IG.

The IG autobuilder populates a few files as it works.  When the IG is failing to publish, you can easily browse to those when visiting the link above.  However, you can also view them when the publisher is working normally by visiting the links below.

### `build.log`
The complete output of the autobuilder is saved here: <https://build.fhir.org/ig/HL7/smart-web-messaging/build.log>

### `qa.html`
The publisher produces an html page containing publication warnings and errors.  View it here: <https://build.fhir.org/ig/HL7/smart-web-messaging/qa.html>

### `builds.html`
You can view all the auto published builds here: <https://fhir.github.io/auto-ig-builder/builds.html>.

# Making Changes
To update the published IG, it is recommended that you test it locally before pushing changes back to the repo.

## Prerequisites
You must have `sushi` to generate the IG.  <https://github.com/FHIR/sushi#installation-for-sushi-users>

To convert the IG into the pulishable HTML content, you will run the latest version of the publisher, which will automatically be downloaded by the build process below.  However, to view the content locally, you must have `jekyll` installed locally.  <https://jekyllrb.com/docs/installation/>

## Testing Locally
Please check out this repo and run the `build.sh` script (see below).  This will run sushi locally on the repo files, then apply the latest publisher to the sushi output to confirm that the publisher will work with the IG.

```shell
# Check out the repo.
mkdir -p ~/code/HL7
cd $_
git clone git@github.com:HL7/smart-web-messaging.git
cd smart-web-messaging

# Build and test the IG using a local sushi and publisher.jar.
./build.sh

# The script will automatically open the local qa.html and index.html in your
# default browser.
```

## Building on Windows

### Prerequisites

1. Install [Node](https://nodejs.org/en/download/)
1. Install FHIR Shorthand
    * Global: `npm install -g fsh-sushi`
    * Local: `npm install fsh-sushi`
1. Install Java (JDK 14 or later)

### Building

1. Run `_updatePublisher.bat` (answer `Y` to all questions)
1. Run `_genonce.bat`
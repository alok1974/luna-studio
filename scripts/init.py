#!/usr/bin/python2.7

###########################################################################
## Copyright (C) Flowbox, Inc / All Rights Reserved
## Unauthorized copying of this file, via any medium is strictly prohibited
## Proprietary and confidential
## Flowbox Team <contact@flowbox.io>, 2014
###########################################################################

import os.path
import sys
import shutil
import platform
import subprocess
from subprocess        import call, Popen, PIPE, check_output, CalledProcessError
from distutils.version import LooseVersion
from utils.colors      import print_info, print_error, putInfo
from utils.errors      import fatal
from utils.net         import download
from utils.system      import platformFix
from utils.process     import ask
import argparse
import tempfile
import glob
from contextlib import contextmanager

SILENTINSTALL = False

rootPath = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))

sboxName = "dist"

os.chdir(rootPath)

def assertInstall(name):
    if not checkAvailable(name):
        print_error ("Please install '%s' to continue" % name)
        fatal()

def checkAvailable(name):
    putInfo ("Checking if '%s' is available ... " % name)
    cmd = "where" if platform.system() == "Windows" else "command -v"
    if call(cmd + " " + name, shell=True): 
        print_info("no")
        return False
    else:
        print_info("yes")
        return True

def checkCabalPkg(name, version="", installUsing=None, check=None):
    if check == None:
        check = name
    if not checkAvailable(check):
        if ask ("Cabal binary '%s' is not available. Should I install it?" % name, SILENTINSTALL):
            pkg = name
            if version: pkg += "-%s" % version
            if installUsing == None:
                installUsing = "cd && cabal install %s" % pkg
            if not issubclass (type(installUsing), str):
                installUsing = "cd && cabal install %s" % installUsing(name, version)
            try_call(installUsing)

        else: fatal ()

def checkCabalVersion():
    minv = '1.19.1'
    print_info ("Checking cabal version (>= %s)" % minv)
    (out, err) = Popen("cabal --numeric-version", stdout=PIPE, shell=True).communicate()
    out = out.lstrip().rstrip()
    if not LooseVersion(out) >= LooseVersion(minv): return (False, "Your %s version is too old (%s)" % ("cabal", out))
    else: return (True, None)

def checkInstall(name, installUsing, chckf):
    (ok, err) = chckf()
    if not ok:
        print_error (err)
        if ask("Should I install it? (%s)" % installUsing, SILENTINSTALL):
            try_call(installUsing)
            (ok, err) = chckf()
            if not ok:
                print_error("Running install command didn't fix the issue!")
                fatal()
        else: fatal()

def checkPythonPkg(package, version=None):
    if version:
        install_cmd = "python2.7 -m pip install --user {package}=={version}".format(**locals())
    else:
        install_cmd = "python2.7 -m pip install --user {package}".format(**locals())

    try:
        res = subprocess.check_output("python2.7 -m pip freeze", shell=True)
        if version:
            version = [int(x) for x in version.split('.')]
        for line in res.splitlines():
            if package in line:
                _, installed_ver = line.split('==')
                installed_ver = [int(x) for x in installed_ver.split('.')]
                if version and installed_ver <= version:
                    if ask("Python package '{package}' too old: {installed_ver} available, {version} required. , SILENTINSTALL"\
                           "Should I upgrade it?".format(**locals())):
                        try_call(install_cmd)
                    else:
                        fatal()
                break
        else:
            if ask("Python package '{package}' not installed. Should I install it?".format(**locals()), SILENTINSTALL):
                try_call(install_cmd)
            else:
                fatal()
    except CalledProcessError, e:
        retcode = e.returncode
        print_error("Sorry, but `pip freeze` returned code {retcode}".format(**locals()))
        fatal()

def try_call(cmd):
    print_info ("Running '%s'" % cmd)
    if call(cmd, shell=True): fatal()




def removeIfExists(pathToRemove):
    if os.path.exists(pathToRemove):
        os.remove(pathToRemove)


@contextmanager
def temporary_directory():
    tmpdir = tempfile.mkdtemp(prefix='flowbox-init')
    yield tmpdir
    shutil.rmtree(tmpdir)

@contextmanager
def changed_cwd(newdir):
    cwd = os.getcwd()
    os.chdir(newdir)
    yield
    os.chdir(cwd)


def install_from_sources(name, version=None):
    with temporary_directory() as tmpPath:
        with changed_cwd(tmpPath):
            if version:
                try_call('cabal get ' + name + "-" + version)
            else:
                try_call('cabal get ' + name)
            [d] = glob.glob(name + "-*")
            with changed_cwd(d):
                try_call('cabal clean')
                try_call('cabal install')

def install_alex_happy(name, version):
    try_call('cabal install alex')
    try_call('cabal install happy')
    return (name)

def main():
    if os.path.exists(sboxName):
        if ask("It seems that sandbox is already initialized. Do you want to clean it before reinitializing?", SILENTINSTALL):
            shutil.rmtree(sboxName)
            removeIfExists("cabal.sandbox.config")

    if not os.path.exists(sboxName):
        os.mkdir(sboxName)

    parser = argparse.ArgumentParser(description='Flowbox Development Environment Initializer')
    parser.add_argument('-y', dest='SILENTINSTALL', action='store_true' , help = 'Install all needed stuff without asking, SILENTINSTALL')
    args = parser.parse_args()

    global SILENTINSTALL
    SILENTINSTALL = args.SILENTINSTALL

    print_info ("Updating git submodules")
    try_call ('git submodule init')
    try_call ('git submodule update')

    print_info ("Fixing platform dependent stuff")
    platformFix(sboxName)

    assertInstall("cabal")

    print_info ("Updating cabal package cache")
    try_call('cd && cabal update')
    checkInstall("cabal", installUsing="cabal install cabal-install", chckf=checkCabalVersion)

    checkCabalPkg("happy")
    checkCabalPkg("alex")
    checkCabalPkg("hspec", check="hspec-discover")

    checkCabalPkg("c2hs", installUsing=install_alex_happy, version="0.16.5")

    checkCabalPkg("gtk2hs-buildtools", installUsing=install_alex_happy, check="gtk2hsC2hs")

    checkCabalPkg("hprotoc-fork", check="hprotoc") # FIXME [KL]: Temporary fix for hprotoc

    print_info ("Generating Protocol Buffers files using genproto")
    path = os.path.join(rootPath, 'scripts', 'genproto')
    try_call ('python2.7 %s' % path)

    print_info ("Generating cabal configs using gencabal")
    path = os.path.join(rootPath, 'scripts', 'gencabal')
    try_call ('python2.7 %s' % path)

    checkPythonPkg("psutil")


    print_info ("Success")
    sys.exit(0)


if __name__ == "__main__":
    main()



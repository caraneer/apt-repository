#!/bin/sh
missng_stuff="";
if [ -z "$(command -v dpkg-scanpackages)" ]; then
	echo "Command dpkg-scanpackages not found" 1>&2;
	missng_stuff="1";
fi;
if [ -z "$(command -v md5sum)" ]; then
	echo "Program md5sum not found" 1>&2;
	missng_stuff="1";
fi;
if [ -z "$(command -v sha1sum)" ]; then
	echo "Program sha1sum not found" 1>&2;
	missng_stuff="1";
fi;
if [ -z "$(command -v sha256sum)" ]; then
	echo "Program sha256sum not found" 1>&2;
	missng_stuff="1";
fi;
if [ -z "$(command -v gpg)" ]; then
	echo "Program gpg not found" 1>&2;
	missng_stuff="1";
fi;
if [ -z "$(command -v gzip)" ]; then
	echo "Program gzip not found" 1>&2;
	missng_stuff="1";
fi;
if [ -z "$(command -v cut)" ]; then
	echo "Program cut not found" 1>&2;
	missng_stuff="1";
fi;
if [ -z "$(command -v wc)" ]; then
	echo "Program wc not found" 1>&2;
	missng_stuff="1";
fi;
if [ -z "$(command -v tree)" ]; then
	echo "Program tree not found" 1>&2;
	missng_stuff="1";
fi;
if [ -n "$missng_stuff" ]; then
	exit 1;
fi;

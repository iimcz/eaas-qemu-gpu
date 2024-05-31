EAAS-QEMU-GPU
===
QEMU container build script for EaaS

BUILD
---

~~In order to build this image, download and add the Blackmagic SDK to the `thirdparty` folder.
Specifically, the following files:
`Blackmagic_Desktop_Video_Linux_12.9.tar`
`Blackmagic_DeckLink_SDK_12.9.zip`~~

The above is currently not needed.

Then a standard `docker buildx` should work.

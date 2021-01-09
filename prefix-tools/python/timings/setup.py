import setuptools

setuptools.setup(
    name="timings",
    version="0",
    author="Alexei Colin",
    author_email="acolin@isi.edu",
    description="Measure time/memory of regions from any source file",
    url="https://github.com/ISI-apex/casper-utils/tree/master/prefix-tools/python/timings",
    packages=setuptools.find_packages(),
    classifiers=[
	    "Programming Language :: Python :: 3",
	    "License :: OSI Approved :: MIT License",
	    "Operating System :: OS Independent",
	    ],
    python_requires='>=3.6',
    )

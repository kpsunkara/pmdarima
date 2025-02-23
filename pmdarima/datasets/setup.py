# -*- coding: utf-8 -*-

import numpy
import os
import platform


def configuration(parent_package='', top_path=None):
    from numpy.distutils.misc_util import Configuration

    config = Configuration('datasets', parent_package, top_path)
    config.add_data_dir('data')
    config.add_subpackage('tests')
    return config


if __name__ == '__main__':
    from numpy.distutils.core import setup
    setup(**configuration(top_path='').todict())

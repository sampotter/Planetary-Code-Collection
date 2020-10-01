from numpy.distutils.core import Extension, setup

ext_modules = [
    Extension(
        name='topo3d',
        sources=[
            'Topo3D/conductionQ2.f90',
            'Topo3D/conductionT2.f90',
        ]
    ),
    Extension(
        name='asteroids',
        sources=[
            'Asteroids/asteroid_fast1.f90',
        ]
    )
]

setup(
    name='pcc',
    author='Norbert Schorghofer',
    ext_modules=ext_modules
)

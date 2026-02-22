cmake_minimum_required(VERSION 3.10.2)

project(baremetal_audio)

add_library( 
        baremetal_audio
        SHARED
        engine.cpp
)

find_library( 
        log-lib
        log
)

target_link_libraries( 
        baremetal_audio
        ${log-lib}
        m 
)
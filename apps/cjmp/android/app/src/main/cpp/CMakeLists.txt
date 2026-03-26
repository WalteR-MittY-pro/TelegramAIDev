cmake_minimum_required(VERSION 3.22.1)

project("jnicjmp")

add_library(jnicjmp SHARED
    cjmp.cpp)


target_include_directories(jnicjmp
    PRIVATE cjmp.h
)

target_link_libraries(jnicjmp
    android
    log)

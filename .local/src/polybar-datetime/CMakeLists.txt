cmake_minimum_required(VERSION 3.16)
project(polybar_datetime LANGUAGES CXX)

add_executable(polybar-datetime main.cpp)
target_compile_features(polybar-datetime PRIVATE cxx_std_20)
target_compile_options(polybar-datetime PRIVATE -Wall -Wextra -Wpedantic)

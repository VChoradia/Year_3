# CMakeLists.txt

FILE(GLOB_RECURSE COMPONENT_SRCS
  ${CMAKE_SOURCE_DIR}/main/*.h
  ${CMAKE_SOURCE_DIR}/main/*.c
  ${CMAKE_SOURCE_DIR}/main/*.cpp
)

set(COMPONENT_ADD_INCLUDEDIRS
  "."
  "../local-sdks/arduino-esp32/variants/feather_esp32"
)
register_component()

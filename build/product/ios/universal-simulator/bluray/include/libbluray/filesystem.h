/*
 * This file is part of libbluray
 * Copyright (C) 2009-2010  Obliter0n
 * Copyright (C) 2009-2010  John Stebbins
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library. If not, see
 * <http://www.gnu.org/licenses/>.
 */

/**
 * @file
 * \brief Filesystem interface
 *
 * File access wrappers can be used to bind libbluray to external filesystem.
 * Typical use case would be playing BluRay from network filesystem.
 */

#ifndef BD_FILESYSTEM_H_
#define BD_FILESYSTEM_H_

#ifdef __cplusplus
extern "C" {
#endif

#include "../libbluray/bluray-fs.h"

/**
 *  Open a file
 *
 *  Prototype for a function that returns BD_FILE_H implementation.
 *
 *  @param filename name of the file to open
 *  @param mode string starting with "r" for reading or "w" for writing
 *  @return BD_FILE_H object, NULL on error
 */
typedef BD_FILE_H* (*BD_FILE_OPEN)(const char* filename, const char *mode);

/**
 *  Open a directory
 *
 *  Prototype for a function that returns BD_DIR_H implementation.
 *
 *  @param dirname name of the directory to open
 *  @return BD_DIR_H object, NULL on error
 */
typedef BD_DIR_H* (*BD_DIR_OPEN) (const char* dirname);

/**
 *  Register function pointer that will be used to open a file
 *
 * @deprecated Use bd_open_files() instead.
 *
 * @param p function pointer
 * @return previous function pointer registered
 */
BD_FILE_OPEN bd_register_file(BD_FILE_OPEN p);

/**
 *  Register function pointer that will be used to open a directory
 *
 * @deprecated Use bd_open_files() instead.
 *
 * @param p function pointer
 * @return previous function pointer registered
 */
BD_DIR_OPEN bd_register_dir(BD_DIR_OPEN p);

#ifdef __cplusplus
}
#endif

#endif /* BD_FILESYSTEM_H_ */

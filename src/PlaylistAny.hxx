/*
 * Copyright (C) 2003-2013 The Music Player Daemon Project
 * http://www.musicpd.org
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#ifndef MPD_PLAYLIST_ANY_HXX
#define MPD_PLAYLIST_ANY_HXX

#include "thread/Mutex.hxx"
#include "thread/Cond.hxx"

class SongEnumerator;
struct input_stream;

/**
 * Opens a playlist from the specified URI, which can be either an
 * absolute remote URI (with a scheme) or a relative path to the
 * music orplaylist directory.
 *
 * @param is_r on success, an input_stream object may be returned
 * here, which must be closed after the playlist_provider object is
 * freed
 */
SongEnumerator *
playlist_open_any(const char *uri, Mutex &mutex, Cond &cond,
		  struct input_stream **is_r);

#endif

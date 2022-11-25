#!/usr/bin/env python3
from os import system, walk
from os.path import getmtime, join
from subprocess import PIPE, run
from sys import exit as s_exit


def get_local_data(_directory, _device):  # retrieves titles and mod times from the local device
    _title_list, _mod_list = [], []
    for _root, _directories, _files in walk(_directory):
        for _filename in _files:
            _title_list.append(join(_root.replace(_directory, '', 1), _filename))
            _mod_list.append(int(getmtime(join(_root, _filename))))
    if _device == 'server':
        for _title in _title_list:
            print(_title.rstrip())
        for _time in _mod_list:
            print(_time)
    return _title_list, _mod_list


def get_remote_data(_user_data):  # retrieves titles and mod times from the remote server
    _titles_mods = run(['ssh', '-i', _user_data[5], '-p', _user_data[2], f"{_user_data[0]}@{_user_data[1]}",
                        f'cd /lib/sshyp; python -c \'import sshync; sshync.get_local_data("{_user_data[4]}", '
                        f'"server")\''], stdout=PIPE, text=True).stdout.split('\n')
    _title_list = _titles_mods[:len(_titles_mods)//2]
    _mod_list = _titles_mods[len(_titles_mods)//2:]
    return _title_list, _mod_list


def sort_titles_mods(_list_1, _list_2):  # creates and returns two lists (of titles and mod times) generated by sorting
    # information from two different, provided lists
    _title_list_2_sorted, _mod_list_2_sorted = [], []
    # title sorting
    for _title in _list_1[0]:
        if _title in _list_2[0]:
            _title_list_2_sorted.append(_title)
    for _title in _list_2[0]:
        if _title not in _title_list_2_sorted:
            _title_list_2_sorted.append(_title)
    # mod time sorting
    for _title in _title_list_2_sorted:
        _mod_list_2_sorted.append(_list_2[1][_list_2[0].index(_title)])
    return _title_list_2_sorted, _mod_list_2_sorted


def make_profile(_profile_dir, _local_dir, _remote_dir, _identity, _ip, _port, _user):  # creates a sshync job profile
    open(_profile_dir, 'w').write(f"{_user}\n{_ip}\n{_port}\n{_local_dir}\n{_remote_dir}\n{_identity}\n")


def get_profile(_profile_dir):  # returns a list of data read from a sshync job profile
    try:
        _profile_data = open(_profile_dir).readlines()
    except (FileNotFoundError, IndexError):
        print('\n\u001b[38;5;9merror: the profile does not exist or is corrupted.\u001b[0m\n')
        _profile_data = None
        s_exit(3)
    # extract data from profile
    _user = _profile_data[0].rstrip()
    _ip = _profile_data[1].rstrip()
    _port = _profile_data[2].rstrip()
    _local_dir = _profile_data[3].rstrip()
    _remote_dir = _profile_data[4].rstrip()
    _identity = _profile_data[5].rstrip()
    return _user, _ip, _port, _local_dir, _remote_dir, _identity


def run_profile(_profile_dir):  # runs a sshync job profile
    _user_data = get_profile(_profile_dir)
    _remote_titles_mods = get_remote_data(_user_data)
    _index_l = sort_titles_mods(_remote_titles_mods, get_local_data(_user_data[3], 'client'))
    _index_r = sort_titles_mods(_index_l, _remote_titles_mods)
    _i = -1
    for _title in _index_l[0]:
        _i += 1
        if _title in _index_r[0]:
            # compare mod times and sync
            if int(_index_l[1][_i]) > int(_index_r[1][_i]):
                print(f"\u001b[38;5;4m{_title[:-4]}\u001b[0m is newer locally, uploading...")
                system(f"scp -pqs -P {_user_data[2]} -i '{_user_data[5]}' '{_user_data[3]}{_title}' "
                       f"'{_user_data[0]}@{_user_data[1]}:{_user_data[4]}{'/'.join(_title.split('/')[:-1]) + '/'}'")
            elif int(_index_l[1][_i]) < int(_index_r[1][_i]):
                print(f"\u001b[38;5;2m{_title[:-4]}\u001b[0m is newer remotely, downloading...")
                system(f"scp -pqs -P {_user_data[2]} -i '{_user_data[5]}' '{_user_data[0]}@{_user_data[1]}:"
                       f"{_user_data[4]}{_title}' '{_user_data[3]}{'/'.join(_title.split('/')[:-1]) + '/'}'")
        else:
            print(f"\u001b[38;5;4m{_title[:-4]}\u001b[0m is not on remote server, uploading...")
            system(f"scp -pqs -P {_user_data[2]} -i '{_user_data[5]}' '{_user_data[3]}{_title}' "
                   f"'{_user_data[0]}@{_user_data[1]}:{_user_data[4]}{'/'.join(_title.split('/')[:-1]) + '/'}'")
    for _title in _index_r[0]:
        if _title not in _index_l[0]:
            print(f"\u001b[38;5;2m{_title[:-4]}\u001b[0m is not in local directory, downloading...")
            system(f"scp -pqs -P {_user_data[2]} -i '{_user_data[5]}' '{_user_data[0]}@{_user_data[1]}:"
                   f"{_user_data[4]}{_title}' '{_user_data[3]}{'/'.join(_title.split('/')[:-1]) + '/'}'")

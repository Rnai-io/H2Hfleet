#!/usr/bin/env python3
"""
Apple Client Secret (JWT) Generator for Supabase / Apple Sign-In
Key ID: WDYVH5QF76
Team ID: H4X9654279
Bundle ID: com.h2hfleet.app
"""
import json
import time
import base64
import subprocess
import os

def b64url(b):
    return base64.urlsafe_b64encode(b).decode('utf-8').rstrip('=')

def generate_jwt(p8_path, key_id="WDYVH5QF76", team_id="H4X9654279", client_id="com.h2hfleet.app", days=180):
    header = {'alg': 'ES256', 'kid': key_id}
    now = int(time.time())
    exp = now + (days * 86400) # Apple max is 180 days

    payload = {
        'iss': team_id,
        'iat': now,
        'exp': exp,
        'aud': 'https://appleid.apple.com',
        'sub': client_id
    }

    h_str = b64url(json.dumps(header, separators=(',', ':')).encode('utf-8'))
    p_str = b64url(json.dumps(payload, separators=(',', ':')).encode('utf-8'))
    data = f'{h_str}.{p_str}'.encode('ascii')

    proc = subprocess.Popen(['openssl', 'dgst', '-sha256', '-sign', p8_path], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    der_sig, _ = proc.communicate(input=data)

    # Convert DER ECDSA signature to IEEE P1363 (raw r || s)
    def der_to_raw(der):
        if der[0] != 0x30: raise ValueError('Invalid DER signature format')
        idx = 2
        if der[1] & 0x80: idx += (der[1] & 0x7f)
        if der[idx] != 0x02: raise ValueError('Invalid DER r tag')
        r_len = der[idx+1]
        r = der[idx+2 : idx+2+r_len]
        idx = idx + 2 + r_len
        if der[idx] != 0x02: raise ValueError('Invalid DER s tag')
        s_len = der[idx+1]
        s = der[idx+2 : idx+2+s_len]
        r = r.lstrip(b'\x00').rjust(32, b'\x00')
        s = s.lstrip(b'\x00').rjust(32, b'\x00')
        return r + s

    raw_sig = der_to_raw(der_sig)
    return f'{data.decode("ascii")}.{b64url(raw_sig)}'

if __name__ == '__main__':
    default_p8 = os.path.expanduser('~/Downloads/AuthKey_WDYVH5QF76.p8')
    if os.path.exists(default_p8):
        print(generate_jwt(default_p8))
    else:
        print("Please specify path to your .p8 file")

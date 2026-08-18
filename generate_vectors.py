
#!/usr/bin/env python3
from speck_reference import speck32_64

def rotr16(v, r):
    return ((v >> r) | (v << (16-r))) & 0xffff

def rotl16(v, r):
    return ((v << r) | (v >> (16-r))) & 0xffff

if __name__ == "__main__":
    import random
    random.seed(32)
    print("// key plaintext expected_ciphertext")
    print("1918111009080100 6574694C A86842F2")
    for _ in range(64):
        k = random.getrandbits(64)
        p = random.getrandbits(32)
        c = speck32_64(k,p)
        print(f"{k:016X} {p:08X} {c:08X}")

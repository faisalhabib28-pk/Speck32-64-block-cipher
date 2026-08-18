
#!/usr/bin/env python3
"""Golden reference model for SPECK32/64."""

MASK = 0xFFFF

def rotr16(v, r):
    return ((v >> r) | (v << (16-r))) & MASK

def rotl16(v, r):
    return ((v << r) | (v >> (16-r))) & MASK

def speck32_64(key, plaintext):
    # key = {k3,k2,k1,k0}; plaintext = {x0,y0}
    rk = [key & MASK]
    l = [
        (key >> 16) & MASK,  # k1
        (key >> 32) & MASK,  # k2
        (key >> 48) & MASK,  # k3
    ]

    for i in range(21):
        li = ((rotr16(l[i], 7) + rk[i]) & MASK) ^ i
        l.append(li)
        rk.append(rotl16(rk[i], 2) ^ li)

    x = (plaintext >> 16) & MASK
    y = plaintext & MASK

    for i in range(22):
        x = ((rotr16(x, 7) + y) & MASK) ^ rk[i]
        y = rotl16(y, 2) ^ x

    return ((x << 16) | y) & 0xFFFFFFFF


if __name__ == "__main__":
    key = 0x1918111009080100
    pt = 0x6574694C
    ct = speck32_64(key, pt)
    print(f"key        = {key:016X}")
    print(f"plaintext  = {pt:08X}")
    print(f"ciphertext = {ct:08X}")
    assert ct == 0xA86842F2
    print("OFFICIAL VECTOR: PASS")

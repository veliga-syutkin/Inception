#!/usr/bin/env python3
"""
Test HTTP and HTTPS connectivity
Usage: python3 test_connection.py
"""

import socket
import ssl
import sys

def test_port(host, port, protocol):
    """Test if a port is open and accepting connections"""
    print(f"\n{'='*50}")
    print(f"Testing {protocol} ({port})")
    print('='*50)
    
    try:
        # Create socket
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(3)
        
        # Try to connect
        result = sock.connect_ex((host, port))
        
        if result == 0:
            print(f"✅ Port {port} is OPEN")
            
            # For HTTPS, try to establish SSL connection
            if port == 443:
                try:
                    context = ssl.create_default_context()
                    context.check_hostname = False
                    context.verify_mode = ssl.CERT_NONE
                    
                    with socket.create_connection((host, port), timeout=3) as sock:
                        with context.wrap_socket(sock, server_hostname=host) as ssock:
                            print(f"✅ SSL/TLS connection successful")
                            print(f"   Protocol: {ssock.version()}")
                except Exception as e:
                    print(f"⚠️  SSL/TLS connection failed: {e}")
            
            # For HTTP, try to send a basic request
            elif port == 80:
                try:
                    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                    sock.settimeout(3)
                    sock.connect((host, port))
                    sock.send(b"GET / HTTP/1.1\r\nHost: " + host.encode() + b"\r\n\r\n")
                    response = sock.recv(1024).decode('utf-8', errors='ignore')
                    print(f"✅ HTTP connection successful")
                    print(f"   Response preview: {response[:100]}...")
                except Exception as e:
                    print(f"⚠️  HTTP request failed: {e}")
            
        else:
            print(f"❌ Port {port} is CLOSED or FILTERED")
            print(f"   Error code: {result}")
        
        sock.close()
        
    except socket.gaierror:
        print(f"❌ Hostname could not be resolved")
    except socket.error as e:
        print(f"❌ Connection error: {e}")
    except Exception as e:
        print(f"❌ Unexpected error: {e}")

def main():
    host = "vsyutkin.42.fr"
    
    print(f"\n{'#'*50}")
    print(f"# Connection Test for {host}")
    print(f"{'#'*50}")
    
    # Test HTTP (should be closed/rejected)
    test_port(host, 80, "HTTP")
    
    # Test HTTPS (should be open)
    test_port(host, 443, "HTTPS")
    
    print(f"\n{'='*50}")
    print("Test completed!")
    print('='*50)

if __name__ == "__main__":
    main()

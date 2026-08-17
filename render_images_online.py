import os
import urllib.request
import zlib
import glob

desktop_path = r"C:\Users\hp\OneDrive\Desktop"
output_folder_puml = os.path.join(desktop_path, "QuitMate_Diagrams_PUML")
output_folder_png = os.path.join(desktop_path, "QuitMate_Diagrams_Images")

os.makedirs(output_folder_png, exist_ok=True)

# PlantUML text encoding algorithm for plantuml.com
def plantuml_encode(plantuml_text):
    zlibencoded = zlib.compress(plantuml_text.encode('utf-8'))
    compressed = zlibencoded[2:-4] # strip zlib header and checksum
    
    plantuml_alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_"
    
    def encode6bit(b):
        return plantuml_alphabet[b & 0x3F]
        
    res = ""
    for i in range(0, len(compressed), 3):
        b1 = compressed[i]
        b2 = compressed[i+1] if i+1 < len(compressed) else 0
        b3 = compressed[i+2] if i+2 < len(compressed) else 0

        c1 = b1 >> 2
        c2 = ((b1 & 0x3) << 4) | (b2 >> 4)
        c3 = ((b2 & 0xF) << 2) | (b3 >> 6)
        c4 = b3 & 0x3F

        res += encode6bit(c1) + encode6bit(c2)
        if i+1 < len(compressed):
            res += encode6bit(c3)
        if i+2 < len(compressed):
            res += encode6bit(c4)
    return res

puml_files = glob.glob(os.path.join(output_folder_puml, "*.puml"))
print(f"Found {len(puml_files)} .puml files to render.")

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, Gecko) Chrome/120.0.0.0 Safari/537.36"
}

rendered_count = 0
for puml_path in puml_files:
    basename = os.path.basename(puml_path)
    filename_no_ext = os.path.splitext(basename)[0]
    out_png = os.path.join(output_folder_png, f"{filename_no_ext}.png")
    
    with open(puml_path, "r", encoding="utf-8") as f:
        content = f.read()
        
    encoded = plantuml_encode(content)
    # Try Kroki API first, fallback to PlantUML server
    urls_to_try = [
        f"https://kroki.io/plantuml/png/{encoded}",
        f"http://www.plantuml.com/plantuml/png/{encoded}"
    ]
    
    success = False
    for url in urls_to_try:
        try:
            req = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(req, timeout=15) as response, open(out_png, 'wb') as out_file:
                out_file.write(response.read())
            print(f"Successfully rendered: {filename_no_ext}.png")
            rendered_count += 1
            success = True
            break
        except Exception as e:
            print(f"Attempt failed for {filename_no_ext} on {url}: {e}")
            
print(f"Finished rendering! Total successfully rendered PNG images: {rendered_count}")

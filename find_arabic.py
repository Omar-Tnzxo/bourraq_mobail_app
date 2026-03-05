import os  
import re  
arabic_pattern = re.compile(r'.*[\\u0600-\\u06FF\\u0750-\\u077F\\u08A0-\\u08FF].*$', re.MULTILINE)  
def scan():  
  for root, _, files in os.walk('lib'):  
    for f in files:  
      if f.endswith('.dart'):  
        path = os.path.join(root, f)  
        with open(path, 'r', encoding='utf-8') as f_in:  
          for i, line in enumerate(f_in):  
            if arabic_pattern.match(line):  
              print(f'{path}:{i+1}: {line.strip()}')  
scan()  

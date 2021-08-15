#! /usr/bin/env python3

# Based on Gale & Church 1993, "A Program for Aligning Sentences in Bilingual Corpora"
import math
import sys

BIG_DISTANCE = 2500

class Region:
    def __init__(self, lines, length): 
        self.lines = lines
        self.length = length

class Alignment:
    def __init__(self): 
        self.x1 = 0
        self.y1 = 0
        self.x2 = 0
        self.y2 = 0
        self.d = 0

def readlines(filename):  
    input_file = open(filename, "r")
    file_text = input_file.read()
  
    lines = file_text.split('\n')
    len_ptr = len(lines)
  
    return (lines, len_ptr)

def length_of_a_region(region):
    result = []
    
    for line in region.lines:
        result.append(len(line))
    
    return result

def region_lengths(regions, n):
    for i in range(n):
        result = length_of_a_region(regions[i])
    
    return result

def seq_align(x, y, nx, ny):
    
    distances = []
    path_x = []
    path_y = []
        
    first_len = nx + 1
    second_len = ny + 1
    distances = [[0] * second_len for c in range(first_len)]
         
    path_x = [[0] * second_len for c in range(first_len)]              
    path_y = [[0] * second_len for c in range(first_len)]
              
    d1 = sys.maxsize
    d2 = sys.maxsize
    d3 = sys.maxsize
    d4 = sys.maxsize
    d5 = sys.maxsize
    d6 = sys.maxsize
    
    for j in range(0, ny + 1):    
        for i in range(0, nx + 1):
            
            if (i > 0 and j > 0):        
                #/* substitution */
                d1 = distances[i-1][j-1] + \
                    two_side_distance(x[i-1], y[j-1], 0, 0)
            else:
                d1 = sys.maxsize
                
            if (i > 0):    
                #/* deletion */
                d2 = distances[i-1][j] + \
                    two_side_distance(x[i-1], 0, 0, 0)
            else:
                d2 = sys.maxsize
                
            if (j > 0):        
                #/* insertion */
                d3 = distances[i][j-1] + \
                    two_side_distance(0, y[j-1], 0, 0)
            else:
                d3 = sys.maxsize
                
            if (i > 1 and j > 0):        
                #/* contraction */
                d4 = distances[i-2][j-1] + \
                    two_side_distance(x[i-2], y[j-1], x[i-1], 0)
            else:
                d4 = sys.maxsize
                
            if (i > 0 and j > 1):        
                #/* expansion */
                d5 = distances[i-1][j-2] + \
                    two_side_distance(x[i-1], y[j-2], 0, y[j-1])
            else:
                d5 = sys.maxsize
                
            if (i > 1 and j > 1):        
                #/* melding */
                d6 = distances[i-2][j-2] + \
                    two_side_distance(x[i-2], y[j-2], x[i-1], y[j-1])
            else:
                d6 = sys.maxsize
 
            dmin = d1
            
            if (d2 < dmin):
                dmin = d2
                
            if (d3 < dmin):
                dmin = d3
                
            if (d4 < dmin):
                dmin = d4
                
            if (d5 < dmin):
                dmin = d5
                
            if (d6 < dmin):
                dmin = d6
                 
            if (dmin == sys.maxsize):
                distances[i][j] = 0
            elif (dmin == d1):
                distances[i][j] = d1                
                path_x[i][j] = i - 1
                path_y[i][j] = j - 1              
            elif (dmin == d2):
                distances[i][j] = d2                
                path_x[i][j] = i - 1
                path_y[i][j] = j                
            elif (dmin == d3):
                distances[i][j] = d3                
                path_x[i][j] = i
                path_y[i][j] = j - 1                
            elif (dmin == d4):
                distances[i][j] = d4                
                path_x[i][j] = i - 2
                path_y[i][j] = j - 1                 
            elif (dmin == d5):
                distances[i][j] = d5                
                path_x[i][j] = i - 1
                path_y[i][j] = j - 2
            else:            
                # /* dmin == d6 */ {
                distances[i][j] = d6                
                path_x[i][j] = i - 2
                path_y[i][j] = j - 2
    n = 0
    
    ralign_dict = {}
    
    i = nx
    j = ny
    while (i > 0 or j > 0):                
        oi = path_x[i][j]       
        oj = path_y[i][j]
        di = i - oi
        dj = j - oj
        
        ralign = Alignment()
        next_ralign = Alignment()
          
        if (di == 1 and dj == 1):
            #/* substitution */            
            ralign.x1 = x[i-1]
            ralign.y1 = y[j-1]
            ralign.x2 = 0
            ralign.y2 = 0
            next_ralign.d = distances[i][j] - distances[i-1][j-1]             
        elif (di == 1 and dj == 0):
            #/* deletion */
            ralign.x1 = x[i-1]
            ralign.y1 = 0
            ralign.x2 = 0
            ralign.y2 = 0
            next_ralign.d = distances[i][j] - distances[i-1][j]    
        elif (di == 0 and dj == 1):
            #/* insertion */
            ralign.x1 = 0
            ralign.y1 = y[j-1]
            ralign.x2 = 0
            ralign.y2 = 0
            next_ralign.d = distances[i][j] - distances[i][j-1]        
        elif (dj == 1):
            #/* contraction */
            ralign.x1 = x[i-2]
            ralign.y1 = y[j-1]
            ralign.x2 = x[i-1]
            ralign.y2 = 0
            next_ralign.d = distances[i][j] - distances[i-2][j-1]     
        elif (di == 1):
            #/* expansion */
            ralign.x1 = x[i-1]
            ralign.y1 = y[j-2]
            ralign.x2 = 0
            ralign.y2 = y[j-1]
            next_ralign.d = distances[i][j] - distances[i-1][j-2]    
        else: 
            #/* di == 2 and dj == 2 */ { /* melding */
            ralign.x1 = x[i-2]
            ralign.y1 = y[j-2]
            ralign.x2 = x[i-1]
            ralign.y2 = y[j-1]
            next_ralign.d = distances[i][j] - distances[i-2][j-2]
        
        ralign_dict[n] = ralign
        ralign_dict[n + 1] = next_ralign
        n = n + 1
        
        i = oi
        j = oj
       
    align_dict = {}
        
    for e in range(0, n):
        align_dict[n-e-1] = ralign_dict[e] 
           
    return (n, align_dict)

def pnorm(z):
    t = 1/(1 + 0.2316419 * z)
    pd = 1 - 0.3989423 *  \
    math.exp(-z * z/2) * \
      ((((1.330274429 * t - 1.821255978) * t \
     + 1.781477937) * t - 0.356563782) * t + 0.319381530) * t
    # /* see Gradsteyn & Rhyzik, 26.2.17 p932 */
    return pd

def match(len1, len2):
    #/* foreign characters per english character */
    foreign_chars_per_eng_char = 1
    
    #/* variance per english character */
    var_per_eng_char = 6.8     
    
    if (len1==0 and len2==0): 
        return 0

    try:
        mean = (len1 + len2/foreign_chars_per_eng_char)/2          
    
        z = (foreign_chars_per_eng_char * len1 - len2)/math.sqrt(var_per_eng_char * mean)
    except ZeroDivisionError:
        z = float(999999999999999999999)
    
    #/* Need to deal with both sides of the normal distribution */
    if (z < 0):
        z = -z
        
    pd = 2 * (1 - pnorm(z))
    
    if (pd > 0):
        return (-100 * math.log(pd))
    else:
        return (BIG_DISTANCE);

def two_side_distance(x1, y1, x2, y2):
    penalty21 = 230        
    #/* -100 * log([prob of 2-1 match] / [prob of 1-1 match]) */
    
    penalty22 = 440
    #/* -100 * log([prob of 2-2 match] / [prob of 1-1 match]) */
    
    penalty01 = 450
    #/* -100 * log([prob of 0-1 match] / [prob of 1-1 match]) */
    
    if (x2 == 0 and y2 == 0):    
        if (x1 == 0):            
            # /* insertion */
            return (match(x1, y1) + penalty01)          
        elif(y1 == 0):        
            # /* deletion */
            return (match(x1, y1) + penalty01)    
        else: 
            #/* substitution */
            return (match(x1, y1))     
    elif (x2 == 0):        
        #/* expansion */
        return (match(x1, y1 + y2) + penalty21)    
    elif (y2 == 0):        
        #/* contraction */
        return (match(x1 + x2, y1) + penalty21)     
    else:                
        # /* melding */
        return (match(x1 + x2, y1 + y2) + penalty22)

def read_thing(f, delim = ".EOS"):
    big_s = []
    s = []
    k = 0
    sentence_dict = {}
    text = ''
    para_count = 0
    for l in f:
        l = l.strip()
        if l == ".EOS":
            key = "%s$%s" % (para_count, len(s))
            sentence_dict[key] = text
            text = ''
            s.append((len(s), k))            
            k = 0
        elif l == ".EOP":
            big_s.append(s)
            para_count = para_count + 1
            s = []
            k = 0
        else:
            k += len(l)
            text = text + ' ' + l
            
    return (big_s, sentence_dict)
   
def old_read_thing(f, delim = ".EOS"):    
    s = []
    k = 0
    sentence_dict = {}
    text = ''
    for l in f:
        l = l.strip()        
        if l == ".EOS":            
            sentence_dict[len(s)] = text
            text = ''
            s.append((len(s), k))            
            k = 0            
        else:
            k += len(l)
            text = text + ' ' + l
    return (s, sentence_dict)

def find_sub_regions(region, delimiter):
    result = []  
    
    region_lines = []
    num_lines = 0
    
    for line in region.lines:
      if delimiter and not(line.find(delimiter) == -1):
          result.append(Region(region_lines, num_lines))
          num_lines = 0
          region_lines = []   
      else:
          region_lines.append(line)
          num_lines = num_lines + 1
      
    if (region_lines): 
      result.append(Region(region_lines, num_lines))
        
    return (result, len(result))

def print_region(region, score):
    
    sentence_text = " ".join(region.lines)
    print(sentence_text)
    #print("score: %s line %s" % (score, sentence_text))
    
def main(input_file1, input_file2, hard_delimiter, soft_delimiter):
    
    (lines1, number_of_lines1) = readlines(input_file1)
    (lines2, number_of_lines2) = readlines(input_file2)
    
    tmp = Region(lines1, number_of_lines1)
    
    (hard_regions1, number_of_hard_regions1) = find_sub_regions(tmp, hard_delimiter)
    
    tmp.lines = lines2
    tmp.length = number_of_lines2
    
    (hard_regions2, number_of_hard_regions2) = find_sub_regions(tmp, hard_delimiter)
   

    if (number_of_hard_regions1 != number_of_hard_regions2):
        print("align_regions: input files do not contain the same number of hard regions" + '\n', file=sys.stderr)
        print("%s" % hard_delimiter + '\n', file=sys.stderr)
        print("%s has %d and %s has %d" % (input_file1, number_of_hard_regions1, \
                                           input_file2, number_of_hard_regions2) + '\n', file=sys.stderr)
        
        return
    
    para_count = 0
    
    while para_count < len(hard_regions1):
        
        (soft_regions1, number_of_soft_regions1) = \
            find_sub_regions(hard_regions1[para_count], soft_delimiter)
            
        (soft_regions2, number_of_soft_regions2) = \
            find_sub_regions(hard_regions2[para_count], soft_delimiter)
                
        print("number of soft: %d %d" % (number_of_soft_regions1, number_of_soft_regions2), file=sys.stderr)
        len1 = []
        for reg in soft_regions1:
            len_lines = 0
            for li in reg.lines:
                len_lines = len_lines + len(li)
            
            len1.append(len_lines)
            
        len2 = []
        for reg in soft_regions2:
            len_lines = 0
            for li in reg.lines:
                len_lines = len_lines + len(li)
            
            len2.append(len_lines)                
                    
        (n, align) = seq_align(len1, len2, number_of_soft_regions1, number_of_soft_regions2)
       
        prevx = 0
        prevy = 0
        ix = 0
        iy = 0
        
        for i in range(0,n):
          a = align[i]
          
          if (a.x2 > 0):
              ix = ix + 1
          elif(a.x1 == 0): 
              ix = ix - 1
              
          if (a.y2 > 0): 
              iy = iy + 1
          elif(a.y1 == 0):
              iy = iy - 1
                            
          if (a.x1 == 0 and a.y1 == 0 and a.x2 == 0 and a.y2 == 0):
              ix = ix + 1
              iy = iy + 1
                        
          ix = ix + 1
          iy = iy + 1
             
          print("*** Link: %d - %d ***" % ((ix-prevx),(iy-prevy)))
          
          while (prevx < ix):
              #/* {if(debug)  fprintf(out1,"Text 1:ix=%d prevx=%d\n",ix,prevx); */
              print_region(soft_regions1[prevx], a.d)
              #print("%s\n" % soft_delimiter, file=sys.stderr)
              prevx = prevx + 1
          
          while (prevy < iy):
              #/* {if(debug) fprintf(out1,"Text 2:iy=%d prevy=%d\n",iy,prevy); */
              print_region(soft_regions2[prevy], a.d)
              #print("%s\n\n" % soft_delimiter, file=sys.stderr)
              prevy = prevy + 1
                  
        para_count = para_count + 1

if __name__=='__main__':
    if len(sys.argv) > 1:
        source_file_name = sys.argv[1]
        target_file_name = sys.argv[2]        
    else:
        sys.exit('Usage: arg1 - source input filename arg2 - target input filename')
    
    main(source_file_name, target_file_name, '.EOP','.EOS')    
    


library(httr)
library(magrittr)
library(rvest)
library(stringr)
library(XML)
library(koRpus)
library(tm)

#####################################################################

## 0. Functions for the script
## 1. Scrape table-info from CRC 649 page
## 2. Scrape &amp; save abstracts of CRC 649 papers

#####################################################################

### 0. Functions for the script:                  ###
  # get body of html files
  totext = function(x){
    # input x is a list containing text from the html files
    xpathApply(x, "//body//text()", xmlValue)[[1]]
  }


### 1. Get the table-info from the CRC 649 page:  ###

  drc = POST("https://sfb649.wiwi.hu-berlin.de/fedc/discussionPapers_formular_content.php",
              body = list(filterTypeName = "filterTypeName:AUTHORS",
                          filteryear = "all",
                          B1 = "Search"), encode = "form")
  abstr_info = read_html(drc) %&gt;%
    html_nodes("body") %&gt;%
    html_nodes("tbody") %&gt;%
    html_nodes("tr") %&gt;%
    html_nodes("tr") %&gt;%
    html_nodes("table") %&gt;%
    `[`(4) %&gt;%
    html_table(header = NA, fill = T)
  abstr_info = abstr_info[[1]]

  # Some page specific manipulations:
  abstr_info = abstr_info[-nrow(abstr_info), ]
  colnames(abstr_info) = c("number", "title", "authors", "projectcode", 
                        "date", "jel", "abstract", "download", 
                        "quantlets", "empty")
  cols       = ncol(abstr_info)
  abstr_info = abstr_info[, -((cols-3):cols)]
  abstr_info = lapply(abstr_info, str_replace_all, "\r\n", "")
  
  # date in date format
  abstr_info$date = as.Date(abstr_info$date, format="%d.%m.%Y")


### 2. Scrape &amp; save the abstracts of RDC-papers  ###
  
  # Get the URLs and parse them
  fromhere = paste0("http://sfb649.wiwi.hu-berlin.de/fedc/DP_abstract.php?id=SFB649DP", 
                     abstr_info$number, ".pdf")
  doc      = lapply(fromhere, function(x){htmlParse(x, encoding = "Latin-1")})
  
  # Get the body of the HTML-files
  plain.text = lapply(doc, totext)
  plain.text = lapply(plain.text, function(x){gsub("\r\n", " ", x)})
  plain.text = lapply(plain.text, function(x){gsub("\n|Abstract:", "", x)})

  # Combine the abstract texts with the paper information
  abstr_info$abstracts = unlist(plain.text)
  
  # Save the object in the 4_Analysis subfolder
  save(abstr_info, file = "StemTFIDF_Abstracts/Abstracts_raw.Rdata")

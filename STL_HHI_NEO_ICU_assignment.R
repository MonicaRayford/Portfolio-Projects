##Load tidyverse library
library(tidyverse)

##Load POS ST Hospital data
load("C:/Users/mdr_1/OneDrive/Documents/RStudio/POS_STHospitals.RData")
View(POS.Hospitals.ST)

#Filter by STL Hospital CBSA Codes
STL.Hospitals <- POS.Hospitals.ST %>% 
  filter(cbsa_code == 41180)
View(STL.Hospitals)
table(STL.Hospitals$term_status)
class(STL.Hospitals$term_status)

#Filter by STL Hospitals that are still open 
STL.Hospitals_open <- STL.Hospitals %>% 
  filter(term_status == "00")
View(STL.Hospitals_open)

##Load CHSP Hospital Linkage file
System_Hospital_File <- read_csv("RStudio/chsp-hospital-linkage-2023.csv")

##Replace missing Health System names with the hospital name
System_Hospital_File$health_sys_name[is.na(System_Hospital_File$health_sys_name)
] <- System_Hospital_File$hospital_name[is.na(System_Hospital_File$health_sys_name)]

##Create new data set with the hospital name and CCN#
##Then rename CCN# to Provider#
System.Names <- System_Hospital_File %>% 
  select(provider_number = ccn,
         system = health_sys_name)

##Remove duplicates from System.Names
System.Names <- unique(System.Names)

##Link dataset STL Hospital with dataset System.Names 
##And only keep STL Hospitals
STL.Hospitals_open.W.Systems <- left_join(STL.Hospitals_open,System.Names, by = "provider_number")

##Rearrange Columns in STL.Hospitals_open.W.Systems
##Move 17th next to the 3rd column
STL.Hospitals_open.W.Systems <- STL.Hospitals_open.W.Systems[ ,c(1:3,17,4:16)]

##Aggregate total beds by system and remove the NA values
STL.Systems <- STL.Hospitals_open.W.Systems %>% 
  group_by(system) %>% 
  summarise(beds = sum(beds_certified, na.rm = TRUE))

##Aggregate total neonatal ICUs by system and remove the NA values
STL.Systems_neonatal <- STL.Hospitals_open.W.Systems %>% 
  group_by(hosp_name) %>% 
  summarise(neonatal = sum(s_neonatal_icu, na.rm = TRUE))

##Arrange in descending order by shares
STL.Systems_neonatal <- STL.Systems_neonatal %>% 
  filter(neonatal > "0") %>% 
  arrange(desc(neonatal))

##Calculate shares by beds
STL.Systems_shares <- STL.Systems %>% 
  mutate(share = beds/sum(beds))

##Arrange in descending order by shares
STL.Systems_shares <- STL.Systems_shares %>% 
  arrange(desc(share))

##Square the Market shares
STL.Systems_sq_shares <- STL.Systems_shares %>% 
  mutate(sq_share = 10000*(share^2))

##Calculate the HHI for STL Hospitals
STL.HHI <- STL.Systems_sq_shares %>% 
  summarise(hhi = sum(sq_share))

##Save a file for STL shares and HHI
save(STL.Systems_sq_shares, STL.HHI, STL.Systems_neonatal, file = "Hospital Market Shares HHI NEONATAL.Rdata")
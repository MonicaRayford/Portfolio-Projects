library(tidyverse)

##Load MPUP2023 DAHCM and LEIE CS POST 2022 Data
load("C:/Users/mdr_1/OneDrive/Desktop/UMKC/UMKC Classes/HLTH_ADM 5578/MPUP2023_DAHCM.RData")
load("C:/Users/mdr_1/OneDrive/Desktop/UMKC/UMKC Classes/HLTH_ADM 5578/LEIE.CS.Post2022.RData")

##Create a new variable that equals 1 for every observation
Controlled.Substance.Post2022$excluded <- 1

##Single out NPI and Excluded columns from Controlled.Substance.Post2022 data
CS.List.for.Merge <- Controlled.Substance.Post2022 %>% 
  select(npi, excluded)

##Merge MPUPDrug.Opioid data and CS.List.for.Merge by NPI
Opioid.w.Excluded <- left_join(MPUPDrug.Opioid, CS.List.for.Merge, by = "npi")

##Change missing values under Excluded column to 0
Opioid.w.Excluded$excluded[is.na(Opioid.w.Excluded$excluded)] <- 0

##Days Opioid were supplied by doctor in 2023
Days.Supply.by.doc <- Opioid.w.Excluded %>% 
  group_by(npi, excluded) %>% 
  summarise(supply = sum(total_day_supply, na.rm = TRUE))

table(Days.Supply.by.doc$excluded)

##T Test to find the average of days supplied by doctor
ttest_ouput <- t.test(supply ~ excluded, data = Days.Supply.by.doc)
ttest_ouput
wilcox.test(supply ~ excluded, data = Days.Supply.by.doc)

##Filter out non excluded from all states 
Non_excluded_more_than_mean <- Days.Supply.by.doc %>%
  filter(excluded == 1)
  
##Days Opioid were supplied by doctor in MO & KS in 2023
Days.Supply.by.doc.MO.KS <- Opioid.w.Excluded %>% 
  filter(state == "MO" | state == "KS") %>% 
  group_by(npi, excluded) %>% 
  summarise(supply = sum(total_day_supply, na.rm = TRUE))

table(Days.Supply.by.doc.MO.KS$excluded)

##Cardiology Doctor's that have been reimbursed more than $2mil in KC


##Filter specialty by Cardiology
CARD.KSMO <- MPUPDoc.KSMO %>% 
  filter(str_detect(specialty, "Cardiology")==TRUE)
table(CARD.KSMO$specialty)

##Sum Cardiology doctors based on allowed amount
CARD.KSMO.by.Allowed <- CARD.KSMO %>% 
  group_by(npi, last_name, first_name, city, state, specialty) %>% 
  reframe(avg_allowed = (n_services*allowed)) %>% 
  arrange(desc(avg_allowed))

##Cardiologists reimbursed more than $2mil
CARD.KSMO.by.Allowed.2MIL <- CARD.KSMO.by.Allowed %>% 
  filter(avg_allowed >= 2000000)

##Save a file for Non excluded providers and Cardiologist reimbursed more than $2mil
save(Non_excluded_more_than_mean.MO.KS, CARD.KSMO.by.Allowed,CARD.KSMO.by.Allowed.2MIL, 
     file = "Opioid Prescriptions and Cardiology Doctors Results.Rdata")

## Load Tidyverse library
library(tidyverse)

##Load SPARCS Discharge CNY2015 dataset
load("C:/Users/mdr_1/Downloads/SPARCS.Discharge.CNY2015.RData")

##Turn off Scientific notations
options(scipen = 999)

##Calculate the percentage of patients per zipcode for Auburn Memorial Hospital
Auburn.counts <- SPARCS.Discharge.CNY2015 %>% 
  filter(hosp_name == "Auburn Memorial Hospital") %>% 
  group_by(patient_zip3) %>% 
  summarise(Auburn.counts = n()) %>% 
  arrange(desc(Auburn.counts)) %>% 
  mutate(zipshsare = Auburn.counts/sum(Auburn.counts))

##Calculate the cumulative zipcode share
Auburn.counts <- Auburn.counts %>% 
  mutate(czipshare = cumsum(zipshsare))

##Create an indicator for zipcodes that are less than .75
Auburn.counts$SSA <- ifelse(Auburn.counts$czipshare<=0.75,1,0)

##Filter out the top zipcode competition areas
AuburnSSA <- Auburn.counts %>% 
  filter(SSA==1) %>% 
  select(patient_zip3,SSA)

#calculate the market share of privately insured for the service area in obstetrics

##Isolate the zip codes in AuburnSSA dataset
SPARCS.Discharge.AuburnSSA <- semi_join(SPARCS.Discharge.CNY2015,AuburnSSA, by = "patient_zip3")

##Filter patients with BCBS or Private Health Insurance as primary payer
SPARCS.Discharge.AuburnSSA.ALLDEP <- SPARCS.Discharge.AuburnSSA %>% 
  filter(primary_payer == "Blue Cross/Blue Shield" | primary_payer == 
                           "Private Health Insurance") 

##Group Hospitals using metrics discharge, days, & total charges
Auburn.ALLDEP.Shares <- SPARCS.Discharge.AuburnSSA.ALLDEP %>% 
  group_by(hosp_name) %>% 
  summarise(discharges = n(),
            days = sum(los, na.rm = TRUE), 
            gross_revenue = sum(charges, na.rm = TRUE))

##Calculating the shares using the Auburn.ALLDEP.shares dataset
Auburn.ALLDEP.Shares <- Auburn.ALLDEP.Shares %>% 
  mutate(share_discharges = discharges/sum(discharges),
         share_days = days/sum(days),
         share_gr_rev = gross_revenue/sum(gross_revenue)) %>% 
  arrange(desc(share_days))

##Filter out Aurburn's top 5 competition and arrange in descending order by shares
Auburn.ALLDEP.Shares_Top5 <- Auburn.ALLDEP.Shares %>% 
  filter(share_days > .035) %>% 
  arrange(desc(share_days))

##Filter out Aurburn's top competition by shares
Auburn.ALLDEP.Shares_Top1 <- Auburn.ALLDEP.Shares %>% 
  filter(share_days > .276) %>% 
  arrange(desc(share_days))

##Print to file Auburn market share results
save(Auburn.ALLDEP.Shares,Auburn.ALLDEP.Shares_Top5,Auburn.ALLDEP.Shares_Top1, file = "AuburnWeek3results.Rdata")

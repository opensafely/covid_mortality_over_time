ckd_rrt = c("No CKD or RRT",
            "CKD stage 3a",
            "CKD stage 3b",
            "CKD stage 4",
            "CKD stage 5",
            "RRT (dialysis)",
            "RRT (transplant)") %>% as.factor()
organ_kidney_transplant = c(
  "No transplant",
  "Kidney transplant",
  "Other organ transplant"
) %>% as.factor()
haem_cancer = c(TRUE, FALSE)
immunosuppression = c(TRUE, FALSE)
data <- 
  expand.grid(ckd_rrt, organ_kidney_transplant, haem_cancer, immunosuppression)
colnames(data) <- c("ckd_rrt", "organ_kidney_transplant", "haem_cancer", "immunosuppression")


data <- 
  data %>%
  mutate(      ckd_rrt_cat = 
                 if_else(ckd_rrt == "No CKD or RRT", FALSE, TRUE),
               organ_kidney_transplant_cat = 
                 if_else(organ_kidney_transplant == "No transplant", FALSE, TRUE),
               
               # marker of impaired vaccine response
               imp_vax = if_else(ckd_rrt_cat | organ_kidney_transplant_cat |
                                   haem_cancer | immunosuppression, TRUE, FALSE))
data %>% View()

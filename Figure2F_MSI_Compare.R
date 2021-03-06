#libraries & custom functions
suppressWarnings(library(data.table))
suppressWarnings(library(plyr))
suppressWarnings(library(dplyr))
suppressWarnings(library(stringr))
suppressWarnings(library(ggplot2))
suppressWarnings(library(reshape2))
suppressWarnings(library(forcats))
suppressWarnings(library(RColorBrewer))
library(purrr)
library(grid)
library(gridExtra)
library(gsheet)
source('/ifs/res/taylorlab/chavans/scripts-orphan/multiplot.R')

specify_decimal = function(x, k) format(round(x, k), nsmall=k)
"%ni%" = Negate("%in%")
curr_date = format(Sys.Date(),"%d-%b-%y")

# GET EQUATION AND R-SQUARED AS STRING
# SOURCE: http://goo.gl/K4yh
lm_eqn = function(df,x,y){
  m = lm(y ~ x, df);
  eq = substitute(italic(y) == a + b %.% italic(x)*","~~italic(r)^2~"="~r2, 
                  list(a = format(coef(m)[1], digits = 2), 
                       b = format(coef(m)[2], digits = 2), 
                       r2 = format(summary(m)$r.squared, digits = 3)))
  as.character(as.expression(eq));                 
}

ex_clin0 = fread('~/tempo-cohort-level/WES_metadata_040620.txt') %>% 
  select(DMP, Cancer_Type_Aggregate, MSI_Exome = MSIscore, MSIWES_Class); 
head(ex_clin0); dim(ex_clin0); 

im_clin0 = fread('~/tempo-cohort-level/IM_metadata_040620.txt') %>% 
  select(DMP, CMO, MSI_IMPACT = MSIscore, MSIscore_Class) %>% 
  distinct(.); dim(im_clin0); head(im_clin0)

comb_msi = left_join(ex_clin0, im_clin0, by = "DMP") %>% distinct(.) 
head(comb_msi)
dim(comb_msi)

print(length(unique(comb_msi$CMO)))
print(length(unique(comb_msi$DMP)))

comb_msi = filter(comb_msi, !(MSI_IMPACT<0)) #1432
head(comb_msi)
dim(comb_msi)

range(comb_msi$MSI_IMPACT)
range(comb_msi$MSI_Exome)

hist(comb_msi$MSI_IMPACT,breaks=10)
hist(comb_msi$MSI_Exome,breaks=10)

#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
print("### MSI plot---->")
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Equation
label = lm_eqn(comb_msi,x=comb_msi$MSI_Exome,y=comb_msi$MSI_IMPACT)
label
# R²
r2 = summary(lm(MSI_IMPACT~MSI_Exome,data=comb_msi))$adj.r.squared
r2
#Spearman Correlation
corr = cor.test(comb_msi$MSI_IMPACT, comb_msi$MSI_Exome,method = "spearman") 
#print(str(corr))
rho = as.numeric(corr$estimate)
rho
### scatter plot LINEAR scale Original
#pdf(file='msi_comparison_022719.pdf', width = 11, height = 8)
msi_plot = ggplot(comb_msi, 
                  aes(x = MSI_IMPACT, y = MSI_Exome)) + 
  coord_fixed() +
  #facet_wrap(~Algorithm) +
  geom_point(alpha = 0.5, size = 3, shape = 16, color = "#08519c") +
  #geom_abline(col = "blue") +
  scale_x_continuous(limits = c(0,50)) +
  scale_y_continuous(limits = c(0,50)) +
  #geom_abline(col = "black",slope=1, intercept =0) + 
  geom_smooth(method=lm, se=FALSE, lty=2) +
  theme_classic(base_size = 16) +
  geom_vline(xintercept = 10, linetype = 'dashed', color = 'red') +
  geom_hline(yintercept = 3.5, linetype = 'dashed', color = 'red') +
  geom_abline(intercept = 0, slope = 1, col = "black") + 
  annotate('text', y = c(3.5)+0.5, x = 40, color = 'darkred', label = c('EXOME MSI high (3.5)'), size = 3.5) +
  annotate('text', x = c(10)-0.5, y = 28, color = 'darkred', label = c('IMPACT MSI high (10)'), size = 3.5, angle = 90) +
  theme(axis.text.x = element_text(colour = "blue")) +
  theme(axis.text.y = element_text(colour = "blue")) +
  theme(plot.title = element_text(colour = "blue", size = 14)) +
  labs(title = paste0("MSI-sensor score","\n",
                      "		R^2 = ",specify_decimal(r2,3),"\n",
                      "		Spearman Correlation = ",specify_decimal(rho,3),"\n"), x = "IMPACT MSI", y = "Exome MSI")
print(msi_plot)

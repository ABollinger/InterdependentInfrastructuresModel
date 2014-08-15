library(ggplot2)
library(sqldf)
library(gridExtra)

#setwd("C:\\Users\\Andrew\\Documents\\TUD\\AndrewBollinger\\projects\\NetlogoModels\\InteractingInfrastructures2\\outputdata\\")
setwd("/home/andrewbollinger/AndrewBollinger/projects/NetlogoModels/InteractingInfrastructures2/outputdata/")
results = read.table("FinalExperiment1.csv", skip = 6, sep = ",", head=TRUE)
results2 = read.table("FinalExperiment2.csv", skip = 6, sep = ",", head=TRUE)
results = rbind(results,results2)

colnames = colnames(results)
colnames[1] = "runNumber"
colnames[2] = "pareto"
colnames[6] = "interdependencies"
colnames[4] = "strategy"
colnames[12] = "timestep"
colnames[13] = "cost"
colnames[14] = "resilience"
colnames[15] = "constructedredundancies"
colnames[16] = "constructedcapacity"
colnames[17] = "demandsatisfaction"
colnames(results) = colnames

results$strategy = as.character(results$strategy)

endresults <- sqldf('select pareto, interdependencies, strategy, resilience, cost from results where timestep = 100')

ggplot(endresults,aes(x=strategy,y=resilience)) + geom_point()
ggplot(endresults,aes(x=strategy,y=resilience)) + geom_boxplot()
ggplot(endresults,aes(x=strategy,y=cost)) + geom_boxplot()
ggplot(endresults,aes(x=strategy,y=resilience / cost)) + geom_boxplot()

endresults_s0 <- sqldf('select resilience, cost from results where timestep = 100 and strategy = "0"')
endresults_s1 <- sqldf('select resilience, cost from results where timestep = 100 and strategy = "1"')
endresults_s2 <- sqldf('select resilience, cost from results where timestep = 100 and strategy = "2"')
endresults_s3 <- sqldf('select resilience, cost from results where timestep = 100 and strategy = "3"')
endresults_s4 <- sqldf('select resilience, cost from results where timestep = 100 and strategy = "4"')

endresults_s1b <- sqldf('select resilience, cost, pareto, interdependencies from results where timestep = 100 and strategy = 1 and cost < 16')

mean(endresults_s2$resilience)

p1 <- ggplot(endresults,aes(x=strategy,y=resilience)) + geom_boxplot() +
  scale_y_continuous('Infrastructure resilience') + scale_x_discrete('Strategy') +
  opts(title="Range of resilience values observed") +
  theme(plot.title = element_text(size = rel(3)), axis.title = element_text(size = rel(3)), 
        axis.text.y=element_text(size = rel(3)), axis.text.x=element_text(size = rel(3)))

p2 <- ggplot(endresults,aes(x=strategy,y=cost)) + geom_boxplot()  +
  scale_y_continuous('Cost (monetary units)') + scale_x_discrete('Strategy') +
  opts(title="Range of cost values observed") +
  theme(plot.title = element_text(size = rel(3)), axis.title = element_text(size = rel(3)), 
        axis.text.y=element_text(size = rel(3)), axis.text.x=element_text(size = rel(3)))

pdf("ModelResultsBoxplot.pdf", height=10, width=20) 
grid.arrange(p1,p2,nrow=1,ncol=2)
dev.off()
png("ModelResultsBoxplot.png", height=800, width=1600) 
grid.arrange(p1,p2,nrow=1,ncol=2)
dev.off()

#CREATE PLOTS UNDER CONDITIONS OF LOW EXTREME EVENT MAGNITUDES

endresults_pareto5 <- sqldf('select pareto, interdependencies, strategy, resilience, cost from results where timestep = 100 and pareto = "5"')

p1 <- ggplot(endresults_pareto5,aes(x=strategy,y=resilience)) + geom_boxplot() +
  scale_y_continuous('Infrastructure resilience') + scale_x_discrete('Strategy') +
  opts(title="Range of resilience values observed") +
  theme(plot.title = element_text(size = rel(3)), axis.title = element_text(size = rel(3)), 
        axis.text.y=element_text(size = rel(3)), axis.text.x=element_text(size = rel(3)))

p2 <- ggplot(endresults_pareto5,aes(x=strategy,y=cost)) + geom_boxplot()  +
  scale_y_continuous('Cost (monetary units)') + scale_x_discrete('Strategy') +
  opts(title="Range of cost values observed") +
  theme(plot.title = element_text(size = rel(3)), axis.title = element_text(size = rel(3)), 
        axis.text.y=element_text(size = rel(3)), axis.text.x=element_text(size = rel(3)))

pdf("ModelResultsBoxplot_pareto5.pdf", height=10, width=20) 
grid.arrange(p1,p2,nrow=1,ncol=2)
dev.off()
png("ModelResultsBoxplot_pareto5.png", height=800, width=1600) 
grid.arrange(p1,p2,nrow=1,ncol=2)
dev.off()


#CREATE LINE PLOTS OF RESILIENCE OVER TIME FOR EACH OF THE STRATEGIES

#plot the mean resilience over time
meanresultspertimestep <- sqldf('select timestep, strategy, avg(demandsatisfaction) as avg_resilience, avg(cost) as avg_cost 
                            from results where timestep != 0 group by strategy, timestep order by strategy, timestep')

ggplot() + geom_line(data=meanresultspertimestep,aes(x=timestep,y=avg_resilience,group=strategy,color=strategy),size=2) +
  scale_y_continuous('Mean infrastructure resilience') + scale_x_continuous('timestep') +
  opts(title="Development of resilience over time under each strategy",legend.direction = "horizontal", legend.position="right") +
  theme(plot.title = element_text(size = rel(3)), axis.title = element_text(size = rel(3)), 
        axis.text.y=element_text(size = rel(3)), axis.text.x=element_text(size = rel(3)), legend.title = element_text(size = rel(3)),
        legend.text=element_text(size=30),legend.direction="vertical",legend.key.height=unit(5,"line"),legend.key.width=unit(8,"line"))

ggsave(file="ResilienceOverTime_MeanPerStrategy.png", width=20, height=15)
ggsave(file="ResilienceOverTime_MeanPerStrategy.pdf", width=20, height=15)

#plot the resilience over time for each strategy
strategylist = as.character(unique(results$strategy))
for (i in 1:length(strategylist)) {
  
  currentstrategy = strategylist[i]
  
  resultspertimestep <- fn$sqldf('select runNumber, timestep, strategy, avg(demandsatisfaction) as avg_resilience, avg(cost) as avg_cost from results 
                               where timestep != 0 and strategy = "$currentstrategy" group by runNumber, timestep order by runNumber, timestep')
  
  ggplot() + geom_line(data=resultspertimestep,aes(x=timestep,y=avg_resilience,group=runNumber))
  
  ggsave(file=paste("ResilienceOverTime_Strategy",currentstrategy,".png", sep = ""))
  ggsave(file=paste("ResilienceOverTime_Strategy",currentstrategy,".pdf", sep = ""))
}

# The TAIL Rating Scheme
We spend most of our lives in buildings. The quality of indoor environment is essential as it may adversely affect our health, well-being, and overall satisfaction. With an increased focus on public health, it has become even more important to keep track of the indoor environmental quality in our buildings. An indoor space with good environment is not just good for our health, but also helps us work, learn and sleep better, and improves the overall quality of our life. Hence, it is relevant to understand and observe continuously the quality of our living spaces. To meet this aim, we need a method to rate the quality of indoor environment. TAIL rating scheme is such a tool.

## The ALDREN Project
The [ALDREN project](https://aldren.eu) was a European Union project that aimed to provide incentives that would increase the rate of deep energy renovations of buildings across Europe. ALDREN stands for Alliance for Deep Renovation in buildings. Some of the tools developed by ALDREN were the measures that ensure that buildings perform as expected concerning energy use and indoor environmental quality and are healthy for occupants. The TAIL rating scheme was developed for indoor environmental quality (IEQ), specifically to verify how IEQ is modified during deep energy renovation. It was also conceived to connect with the potential non-energy, economic benefits of energy renovations of buildings.

## The TAIL Rating Scheme
The TAIL rating scheme stands for Thermal, Acoustic, Indoor Air Quality, and Luminous. These are the four parts of an indoor environment that it checks. The TAIL rating scheme referred to existing standards, codes and guidelines to ensure no adverse effects on building occupants.

The TAIL rating provides information on all four components and uses four colours - Green, Yellow, Orange, and Red - to show how good or bad the quality is. The overall quality of the indoor space is derived from the worst quality of each component. A Roman numeral between I and IV shows the overall quality level. The lower the score, the better the indoor space. TAIL is described in this [publication](https://www.sciencedirect.com/science/article/pii/S0378778821003133), introducing the TAIL rating scheme. 


### What TAIL measures
The TAIL system uses twelve things to check the quality of indoor environments:

* Thermal: The temperature of the air inside
* Acoustic: How noisy it is
* Indoor Air Quality: How fast fresh air comes in, the amount of carbon dioxide, formaldehyde, and PM2.5 (tiny dust particles), the humidity, and if there’s any visible mould (checked by a walk-through inspection)
* Light: How bright it is and how much daylight there is (daylight fraction checked by simulating the building’s performance)

The TAIL scheme is meant to be flexible. It can be adapted to different types of buildings, requirements, and locations (depending on local guidelines and laws). TAIL can be extended, with addition of other parameters that are relevant to the indoor environment and some of the existing parameters may be substituted depending on the local codes and guidelines. 

TAIL gives equal importance to all four dimensions of indoor environment that it evaluates, without using any kind of weighting formula. It is also conservative in that it highlights the worst rated component of a building's indoor environment, drawing attention to aspects that need immediate attention and action.

### Going forward with TAIL
TAIL was created with big energy improvement projects in mind, but it can be used for more than that. It can be used for rating both existing and new buildings. A further development, called [PredicTAIL](https://www.sciencedirect.com/science/article/pii/S037877882200010X) can be used in design phase to evaluate a building design. TAIL presents to all variety of users, with different levels of technical know-how, a simple manner of communicating indoor environmental rating and a significant level of flexibility to evolve, without compromising the core idea.

TAIL can be a useful tool for building owners to protect their investments. If the quality of an indoor space is poor and makes people uncomfortable, it can create an economic loss by lowering the building's value or interest among potential buyers or renters. TAIL can help make communication about the quality of indoor spaces easier and more reliable between investors, managers, owners, people using the buildings, and professionals. TAIL is also useful for anyone who wants to learn more about the quality of their indoor spaces or who is just interested in what makes up indoor environmental quality. A bonus of TAIL is that it encourages people to monitor the quality of indoor spaces.

## An aid to evaluating TAIL rating from monitored data
This repository hosts the code for evaluating TAIL rating scheme of an indoor space from measured data. The code is being shared under CC BY-SA license: free to reuse with attribution and derivatives to be shared under similar terms. The intention is to make it easy for monitored data, collected from several buildings to be processed together and TAIL ratings be calculated for individual buildings through this code. We are hosting the code as an open-source repository so that anyone can use this as an aid to calculate TAIL ratings and they can also develop further on it, as per their needs. 

We also provide the algorithm behind the code in a text file called TAIL_algorithm.txt. The code uses csv files as inputs with specific column headings. A sample csv file with this structure has also been provided. To use the code, naming conventions and units observed in this file should be emulated by users. The code shared in this repository is in R. We have also created a [Google Colab](https://colab.research.google.com/drive/1syLYNQJuKt3-UC2ISOF8GYqWQsH-yVbX?usp=drive_link) notebook with a version of the code in Python. Users may choose whichever envrionment suits them the most.

### Using the code
Here is a quick [introduction video](https://youtu.be/hAK0kMrOA2U) on how to use the repositiory. 
Download the sample csv file (TAILSampleData.csv) and use it to format your data. The data needs to have the following columns:
* Building: name of the building. You can use a building name or a code as long as each building in the dataset has its unique name.
* Room: name or number for room where the data was monitored
* Sensor: sensor brand name. This column does not contribute to the calculations. It is for your records.
* Date_Time: a timestamp column. The format of timestamp will depend on the monitor you are using. The default in the code is dd/mm/yyyy hh:mm:ss. You can modify this based on the kind of timestamp used by your monitor
* Variable: name of the TAIL parameter measured. Day light factor and mold are not measured data but the code assumes that these values have been added to the dataframe so that you can calculate TAIL rating in a single step. It is possible that a certain measurement campaign did not evaluate all the parameters. In such a case, the schematic puts parameters that were not measured in gray. The TAIL rating is then based on the parameters that were measured.
* Unit: unit of measurements for the parameters. It is important that users provide values in the units that have been mentioned here.
* Value: measured value.
* BuildingType: type of building where the monitoring was carried out. The current version accounts for two building types - Office and Hotel.
* RoomType: room type is used for noise labelling. Currently, three room types are included in the process - Small office, Open office, and Hotel.
* Occupancy: design occupancy of the room. Given in number of people
* FloorArea: floor area of the room. Given as square meters. 

The data structure is designed to be long-from data - measured data for different parameters, even if they were measured at the same time, follow each other on subsequent rows. This allows you to use data from different monitors, with different logging frequency, in the rating process. This also makes it easy to add parameters like mold and daylight factor, which are not measured, to the dataframe.  

The code requires you to have R installed on your system. In your R project, change the working directory to where you have the data. Assign the name of your csv file to the file being imported in the code. The code can then be run to go through the data and create a graphical TAIL rating scheme for each building and a csv file with the TAIL ratings for all buildings for which you have monitored data.

The output includes a TAIL rating schematic for each building in your database (an example below) and a table of the ratings for individual components and the overall rating for each building. 'NA' values indicate the specific parameter was not evaluated during the monitoring process.


|Building|	TAIL|	TAILLabel	|TempLabel|	DFLabel|	LuxLabel|	CO2Label|	RHLabel|	BenzeneLabel|	FormaldehydeLabel|	PM2.5Label|	RadonLabel|	VentilationLabel|	MoldLabel|	NoiseLabel|
|----|	----|	----|	----|	----|	----|	----|	----|	----|	----|	----|	----|	----|	----|	----|
|A333|	Red|	4|	2|	NA|	4|	1|	1|	NA|	1|	1|	NA|	NA|	NA|	4|



<img src="https://github.com/user-attachments/assets/d1c4c82c-bebb-43c8-a425-951756bdeec3" width="400" height="400">


This repository for TAIL rating calculations was carried out as part of a [Dorothy fellowship](https://dorothy.ie) (awardee: Asit Kumar Mishra).

<img src="https://github.com/user-attachments/assets/26ef327e-0f17-4cfe-af0d-75e5cc8edeb6" width="544" height="252">


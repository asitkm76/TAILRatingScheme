# The TAIL Rating Scheme
We spend most of our lives inside buildings. So, the quality of these indoor spaces really affects our health and happiness. As we focus more on public health, it's important to check how good or bad these indoor spaces are. A good indoor space is not just good for our health, but also helps us work better and improves our life. Hence it is relevant to understand the quality of our living spaces.

## The ALDERN Project
The [ALDREN project](https://aldren.eu), led by the CSTB (Centre Scientifique et Technique du Bâtiment), was a European Union project that aimed to improve energy use in buildings across Europe. ALDERN stands for Alliance for Deep Renovation in buildings. The project wanted to provide tools and measures that make sure buildings perform as expected, including being healthy for people to use.
A big part of the ALDREN project was checking the quality of indoor spaces in buildings that have had major energy improvements.

## The TAIL Index
As part of the ALDREN project, a new way to check indoor spaces was suggested. It is called the TAIL rating scheme, which stands for Thermal, Acoustic, Indoor Air Quality, and Luminous. These are the four parts of an indoor environment that it checks. The TAIL rating scheme is meant to work with other indoor environmental standards and health-based guidelines for exposures, particularly, to air pollutants. 

The TAIL index checks each part and uses four colours - Green, Yellow, Orange, and Red - to show how good or bad each part is. The overall quality of the indoor space is then decided based on the worst part. A Roman numeral shows the overall quality level. The lower the score, the better the indoor space. For more information on TAIL, you can consult the original [publication](https://www.sciencedirect.com/science/article/pii/S0378778821003133) introducing the TAIL rating scheme. 

### What TAIL measures
The TAIL system uses twelve things to check the quality of indoor environments:

* Thermal: The temperature of the air inside
* Acoustic: How noisy it is
* Indoor Air Quality: How fast fresh air comes in, the amount of carbon dioxide, formaldehyde, and PM2.5 (tiny dust particles), the humidity, and if there’s any visible mould (checked by a walk-through inspection)
* Light: How bright it is and how much daylight there is (daylight fraction checked by simulating the building’s performance)

The TAIL scheme is meant to be flexible. It can be adapted to different types of buildings, requirements, and locations (depending on local guidelines and laws). We can add other parameters that are relevant to the indoor environment and some of the existing parameters may be substituted. For example, in locations where Radon is known to be a problem, we can add Radon to the indoor air quality portion of the index. 

### Going forward with TAIL
TAIL was created with big energy improvement projects in mind, but it can be used for more than that. It can be used for rating both existing and new buildings. A further development, called [PredicTAIL](https://www.sciencedirect.com/science/article/pii/S037877882200010X) can be used in design phase to evaluate a building design. 

TAIL can be a useful tool for building owners to protect their investments. If the quality of an indoor space is poor and makes people uncomfortable, it can lower the building's value. TAIL can help make communication about the quality of indoor spaces easier and more reliable between investors, managers, owners, people using the buildings, and professionals. TAIL is also useful for anyone who wants to learn more about the quality of their indoor spaces or who is just interested in what makes up an indoor space. A bonus of TAIL is that it encourages people to monitor the quality of indoor spaces.

## An aid to evaluating TAIL rating from monitored data
This repository hosts the code for evaluating TAIL rating scheme of an indoor space from measured data. The code is being shared under CC BY-SA license: free to reuse with attribution and derivatives to be shared under similar terms. The intention is to make it easy for monitored data, collected from several buildings to be processed together and TAIL ratings be calculated for individual buildings through this code. 

We also provide the algorithm behind the code in a text file called TAIL_algorithm.txt. The code uses csv files as inputs with specific column headings. A sample csv file with this structure has also been provided. To use the code, naming conventions and units observed in this file should be emulated by users. The current code is in R. We plan to supplement these with Python scripts subsequently. 

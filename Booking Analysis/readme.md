# 🧠 European Booking Data Analysis – SQL Assignment

## 📌 Problem Statement

A company managing short-term rentals across multiple European cities is seeking deep insights from its booking data. The goal is to:

- Identify trends in booking behavior
- Understand pricing and satisfaction metrics
- Detect outliers in pricing
- Explore city-level and room-type-based booking patterns

You are tasked with performing a comprehensive SQL-based analysis on this dataset using multiple dimension and fact tables.

---

## 🗂️ Dataset Overview

### Fact Table

- **fact\_data** – Contains booking details such as Price, Guest Satisfaction, Cleanliness Rating, DayTypeID, RoomTypeID, and city ID reference

### Dimension Tables

- **dim\_city** – Maps city names to CityIDs
- **dim\_room\_type** – Contains room type categories
- **dim\_day\_type** – Maps day types (Weekday/Weekend) to DayTypeIDs
- **dim\_personCapacity.csv** – Maps day types (Weekday/Weekend) to DayTypeIDs

---


## 💡 Key Insights

- Large variation exists in price due to outliers.
- Guest satisfaction varies significantly by city.
- Room types and booking days influence both revenue and satisfaction.
- Cleaned data provides more realistic average prices for business insights.

---


# Use an official Python runtime as a parent image
FROM python:3.9-slim-buster

# Create a new directory called "app"
RUN mkdir /app

# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install any needed packages specified in requirements.txt
RUN pip3 install -r requirements.txt

# Define environment variables
ENV EMAIL "brettmmele@gmail.com"
ENV PASSWORD "uX8ZARtpyVe6wZX"

# Run the command to start the container
CMD ["python3", "main.py"]
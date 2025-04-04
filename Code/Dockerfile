FROM python:3.9-slim-buster

# Create a non-root user and group
RUN groupadd -r myuser && useradd -r -g myuser myuser

# Set the working directory
WORKDIR /app

# Copy the application files
COPY . /app

# Install dependencies (Flask)
RUN pip install --no-cache-dir Flask

# Set ownership of the application directory to the non-root user
RUN chown -R myuser:myuser /app

# Switch to the non-root user
USER myuser

# Expose the port the application listens on
EXPOSE 5000

# Command to run the application
CMD ["python3", "sts.py"]

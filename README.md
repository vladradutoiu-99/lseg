Description:

The project consists of a small application with 2 API endpoints.
The API endpoints are accessible at http://34.107.33.105 and have a rate limit of 30 requests per minute. The limit is shared between the 2 endpoints

Endpoint 1:
 - '/stock-service/api-consecutive-datapoints', uses POST method and takes 2 paramters
 "processed_files": int, "max_concurrent_threads": Optional[int]

 processed_files represent the number of files to be selected from each folder. The files
 are stored locally on the Docker image. The files are read using pandas.
 If the number of files available is less than processed_files, all of them will be used.
 I have assumed that the files do not have to be manually uploaded by api and could be served static or from cloud storage.
 This helped speed up development.

 max_concurrent_threads represents the number of threads to be used while processing the files.
 Default is 1.

 Returns a Dictionary with field "folders" with fields "folder_name" and "files"
 Files represents a list of dictionaries with fields "file_name" and "random_rows"
 random_rows is a list of 10 rows starting from a random point in the original csv sorted ascending.
 If there are less than 10 rows starting from the random point, there will be returned only the remaining ones.

 Example response: {
  "folders": [
    {
      "folder_name": "NYSE",
      "files": [
        {
          "file_name": "ASH.csv",
          "random_rows": [
            {
              "STOCK_ID": "ASH",
              "TIMESTAMP": "10-11-2023",
              "PRICE": 110.54
            },
            {
              "STOCK_ID": "ASH",
              "TIMESTAMP": "11-11-2023",
              "PRICE": 110.65
            },
            {
              "STOCK_ID": "ASH",
              "TIMESTAMP": "12-11-2023",
              "PRICE": 112.2
            },
            {
              "STOCK_ID": "ASH",
              "TIMESTAMP": "13-11-2023",
              "PRICE": 112.53
            },
            {
              "STOCK_ID": "ASH",
              "TIMESTAMP": "14-11-2023",
              "PRICE": 111.52
            },
            {
              "STOCK_ID": "ASH",
              "TIMESTAMP": "15-11-2023",
              "PRICE": 110.96
            },
            {
              "STOCK_ID": "ASH",
              "TIMESTAMP": "16-11-2023",
              "PRICE": 110.85
            },
            {
              "STOCK_ID": "ASH",
              "TIMESTAMP": "17-11-2023",
              "PRICE": 112.4
            },
            {
              "STOCK_ID": "ASH",
              "TIMESTAMP": "18-11-2023",
              "PRICE": 112.4
            },
            {
              "STOCK_ID": "ASH",
              "TIMESTAMP": "19-11-2023",
              "PRICE": 113.08
            }
          ]
        }
      ]
    }
   
  ]
}

Endpoint 2:
 - - '/stock-service/api-predict-stock-price', uses POST method
 It takes the first endpoint output as parameter
 Optionally it has "max_concurrent_threads" as parameter to specify the number of threads to be used

 The algorithm used is the one provided in the challenge.
 For further development, an ARMA model could be used: 
 https://www.deanfrancispress.com/index.php/te/article/view/883/TE001192.pdf

 Returns a zip file containing the files structured in folders.


 The application runs on a Docker image on kubernetes, hosted on a GCP account.
 The docker images are stored in artifact registry, and the process of CI/CD is
 written using Github Actions.

 The infrastructure was created using a terraform script. 

 Limitations:
 Due to time constrains, I could not implement a different algorithm for predicting the datapoints.
 The application does not have a domain name, a static IP address or a SSL certificate.
 It has a database accessible in cluster but it was not used for any operation
 It does not have an option to upload files, so only the static files from the Docker image are used.
 It does not have any vertical or horizontal scaling strategies.
 It does not have any event-driven actions.
 The logging does not use any from ELK stack or Grafana, Prometheus.

 Credits:
 The implementation of zalando-postgres was helped by google documentation: 
 https://cloud.google.com/kubernetes-engine/docs/tutorials/stateful-workloads/postgresql
 Everything else was created using previous knowledge and libraries documentation.




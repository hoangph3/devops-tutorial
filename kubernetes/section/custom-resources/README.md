### Configure the CustomResourceDefinitions

To define a new resource type, all you need to do is post a `CustomResourceDefinition` object (CRD) to the Kubernetes API server. The `CustomResourceDefinition` object is the description of the custom resource type. Once the CRD is posted, users can then create instances of the custom resource by posting JSON or YAML manifests to the API server, the same as with any other Kubernetes resource.

Let's imagine you want to allow users of your Kubernetes cluster to run static websites as easily as possible, without having to deal with `Pods`, `Services`, and other Kubernetes resources. What you want to achieve is for users to create objects of type `Website` that contain nothing more than the website's name and the source from which the website's files (HTML, CSS, PNG, and others) should be obtained, eg., docker image, github, ... When a user creates an instance of the `Website` resource, you want Kubernetes to spin up a new web server pod and expose it through a Service.

Ensure you have create web-demo directory:

``` 
web-demo
├── index.html
└── subdir
    └── index.html

1 directory, 2 files
```

To create the `Website` resource, you want users to post manifests along the lines of the one shown in the following listing.

```yaml
apiVersion: extensions.example.com/v1
kind: Website
metadata:
  name: web-demo
spec:
  src: https://github.com/luksa/kubia-website-example.git
```

If you try posting this resource to Kubernetes, you'll receive an error because Kubernetes doesn’t know what a `Website` object is yet:

```
$ kubectl apply -f imaginary-website.yaml    
error: unable to recognize "imaginary-website.yaml": no matches for kind "Website" in version "extensions.example.com/v1"
```

Now you will create the CRD from the `website-crd.yaml` file:

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: websites.extensions.example.com
spec:
  scope: Namespaced
  group: extensions.example.com
  versions:
    - name: v1
      served: true
      storage: true
  names:
    kind: Website
    singular: website
    plural: websites
```


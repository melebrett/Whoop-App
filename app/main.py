import webapp2

class HelloWorld(webapp2.RequestHandler):

    def get(self):
        self.response.write('Hello from The App')

app = webapp2.WSGIApplication([
  ('/', HelloWorld),
])
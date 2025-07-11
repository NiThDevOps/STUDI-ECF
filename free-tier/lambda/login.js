// https://docs.aws.amazon.com/fr_fr/lambda/latest/dg/getting-started.html

exports.handler = async (event) => {
  const body = JSON.parse(event.body || '{}');
  const { username, password } = body;

  if (username === 'admin' && password === 'admin123') {
    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Login OK', token: 'fake-jwt-token' }),
    };
  }

  return {
    statusCode: 401,
    body: JSON.stringify({ message: 'Unauthorized' }),
  };
};
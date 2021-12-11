export default (req, res) => {
  const receivedArgs = [];
  if (req.body.arg) receivedArgs.push(req.body.arg);
  if (req.query.arg) receivedArgs.push(req.query.arg);

  res
    .status(200)
    .send({ receivedArgs });
};

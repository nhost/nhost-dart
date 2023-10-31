import { Request, Response } from "express";

export default (req: Request, res: Response) => {
	const receivedArgs = [];
	if (req.body.arg) receivedArgs.push(req.body.arg);
	if (req.query.arg) receivedArgs.push(req.query.arg);

	res.status(200).send({ receivedArgs });
};

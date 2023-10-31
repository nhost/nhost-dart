import { Request, Response } from "express";

export default (req: Request, res: Response) => {
	throw new Error("Test error");
};

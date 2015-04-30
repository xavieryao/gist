express = require 'express'
fs = require 'fs'
db = require '../db'

router = express.Router()

getFilePath = (id,lang)->
	path = __dirname + "/../../uploads/#{id}.#{lang}"

router.get '/create',(req,res,next)->
	console.log 'get'
	if req.user
		res.render 'create',user:req.user
	else
		req.flash 'type','warning'
		req.flash 'msg','You must login first'
		res.redirect 'back'

router.post '/create',(req,res,next)->
	if not req.user?
		e = new Error 'Unauthorized'
		e.status = 403
		return next e
	gist =
		title : req.body.title
		filetype : req.body.lang
		description : req.body.description || 'NULL'
		uid : req.user.id

	if req.body.description?
		gist.description = req.body.description

	sql = 'INSERT INTO gists SET ?'

	db.query sql,gist,(err,r)->
		throw err if err
		path = getFilePath r.insertId,req.body.lang
		fs.writeFile path,req.body.code,(err)->
			if err
				console.error err
				next err
			else
				res.send 'Good!  ' + path
				res.end()

router.get '/:id',(req,res,next)->
	sql = 'SELECT * FROM gists WHERE id = ?'
	db.query sql,[req.params.id],(err,results,fields)->
		return next err if err
		if results.length != 0
			r = results[0]
			path = getFilePath req.params.id,r.filetype
			fs.readFile path,encoding:'utf8',(err,content)->
				return next err if err
				res.render 'create',
					code:content
					user:req.user
		else next()

module.exports = router